import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';
import '../../exercises/data/exercise_repository.dart';
import '../../exercises/models/exercise.dart';
import '../../exercises/models/planned_exercise.dart';
import '../../exercises/controllers/exercise_controller.dart';
import '../data/package_repository.dart';
import '../models/workout_package.dart';

class EditPackagePage extends StatefulWidget {
  const EditPackagePage({super.key, this.package});

  final WorkoutPackage? package;

  @override
  State<EditPackagePage> createState() => _EditPackagePageState();
}

class _EditPackagePageState extends State<EditPackagePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> categories = ['Tümü', 'Sırt', 'Göğüs', 'Bacak', 'Kardiyo', 'Omuz'];
  String selectedCategory = 'Tümü';
  final ExerciseRepository _exerciseRepository = ExerciseRepository();
  final PackageRepository _packageRepository = PackageRepository();

  bool _loading = false;
  bool _saving = false;
  List<Exercise> _exercises = const [];
  final List<PlannedExercise> _planned = [];

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'demoUser';

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _nameController.text = widget.package!.name;
      _descriptionController.text = widget.package!.description ?? '';
      _planned.addAll(widget.package!.exercises);
    }
    _searchController.addListener(_onSearchChanged);
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _loading = true);
    try {
      final results = await _exerciseRepository.searchExercises(
        query: _searchController.text,
        category: selectedCategory == 'Tümü' ? null : selectedCategory,
      );
      setState(() {
        _exercises = results;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      Get.snackbar('Hata', 'Egzersizler alınamadı: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _onSearchChanged() {
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.isNotEmpty || selectedCategory != 'Tümü';

    return Scaffold(
      appBar: FittaAppBar(
        title: widget.package == null ? 'Yeni Paket Oluştur' : 'Paketi Düzenle',
      ),
      body: RefreshIndicator(
        onRefresh: _loadExercises,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Paket Adı',
                        hintText: 'Örn: Başlangıç Seviyesi Full Body',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (Opsiyonel)',
                      ),
                    ),
                  ),
                  AppSpacing.vMd,
                  const Divider(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: selectedCategory == c,
                          onSelected: (_) {
                            setState(() => selectedCategory = c);
                            _loadExercises();
                          },
                        ),
                      )).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Egzersiz ara',
                        prefixIcon: Icon(CupertinoIcons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  AppSpacing.vSm,
                ],
              ),
            ),
            if (isSearching) ...[
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_exercises.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Egzersiz bulunamadı')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = _exercises[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: FittaCard(
                          child: ListTile(
                            title: Text(exercise.name),
                            subtitle: Text(exercise.category),
                            trailing: IconButton(
                              icon: const Icon(CupertinoIcons.add_circled_solid),
                              onPressed: () => _openBottomSheet(exercise),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _exercises.length,
                  ),
                ),
            ],
            if (!isSearching || _planned.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       if (!isSearching && _planned.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(child: Text('Paket içeriği boş. Egzersiz ekleyin.')),
                        )
                      else ...[
                        Text(
                          'Paket İçeriği (${_planned.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        AppSpacing.vSm,
                        ..._planned.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FittaCard(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                p.type == 'time'
                                    ? '${p.sets} set x ${p.seconds ?? p.reps} sn'
                                    : '${p.sets} set x ${p.reps} tekrar',
                              ),
                              trailing: IconButton(
                                icon: const Icon(CupertinoIcons.trash),
                                onPressed: () => setState(
                                  () => _planned.removeWhere((e) => e.exerciseId == p.exerciseId),
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(
          label: _saving ? 'Kaydediliyor...' : 'Paketi Kaydet',
          icon: const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
          onPressed: _saving ? null : _savePackage,
        ),
      ),
    );
  }

  Future<void> _openBottomSheet(Exercise exercise) async {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    String type = 'weight';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.name, style: Theme.of(context).textTheme.titleMedium),
              AppSpacing.vMd,
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Set'),
              ),
              AppSpacing.vSm,
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tekrar / Süre'),
              ),
              AppSpacing.vSm,
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Tür'),
                items: const [
                  DropdownMenuItem(value: 'weight', child: Text('Weight')),
                  DropdownMenuItem(value: 'time', child: Text('Time')),
                  DropdownMenuItem(value: 'reps', child: Text('Reps')),
                ],
                onChanged: (val) => type = val ?? 'weight',
              ),
              AppSpacing.vMd,
              PrimaryButton(
                label: 'Ekle',
                onPressed: () {
                  Get.back();
                  _addPlannedExercise(
                    exercise: exercise,
                    sets: setsController.text,
                    reps: repsController.text,
                    type: type,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPlannedExercise({
    required Exercise exercise,
    required String sets,
    required String reps,
    required String type,
  }) {
    final parsedSets = int.tryParse(sets) ?? 0;
    final parsedReps = int.tryParse(reps) ?? 0;
    final seconds = type == 'time' ? parsedReps : null;
    final planned = PlannedExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      category: exercise.category,
      description: exercise.description,
      sets: parsedSets,
      reps: type == 'time' ? 0 : parsedReps,
      weight: null, // Packages are usually generic, weight is personal
      seconds: seconds,
      type: type,
    );
    setState(() {
      _planned.add(planned);
    });
    Get.snackbar('Paket', '${exercise.name} pakete eklendi', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _savePackage() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Uyarı', 'Lütfen paket adı girin', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_planned.isEmpty) {
      Get.snackbar('Uyarı', 'Paket boş. Egzersiz ekleyin.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _saving = true);
    try {
      final pkg = widget.package?.copyWith(
        name: name,
        description: _descriptionController.text.trim(),
        exercises: _planned,
      ) ?? WorkoutPackage(
        id: '', // Repo generates ID if empty
        ownerUserId: _userId,
        name: name,
        description: _descriptionController.text.trim(),
        exercises: _planned,
        createdAt: DateTime.now(),
      );

      await _packageRepository.savePackage(userId: _userId, package: pkg);
      Get.back();
      Get.snackbar('Başarılı', 'Paket kaydedildi', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', 'Paket kaydedilemedi: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
