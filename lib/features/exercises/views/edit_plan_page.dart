import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';
import '../data/exercise_repository.dart';
import '../models/exercise.dart';
import '../models/planned_exercise.dart';
import '../controllers/exercise_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPlanPage extends StatefulWidget {
  const EditPlanPage({super.key, this.userId});

  final String? userId;

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _planNameController = TextEditingController();
  final List<String> categories = [
    'Tümü',
    'Sırt',
    'Göğüs',
    'Bacak',
    'Karın',
    'Kardiyo',
    'Omuz',
  ];
  String selectedCategory = 'Tümü';
  final ExerciseRepository _repository = ExerciseRepository();
  bool _loading = false;
  bool _saving = false;
  List<Exercise> _exercises = const [];
  final List<PlannedExercise> _planned = [];
  late final Map<String, bool> _selectedDays;

  String get _userId =>
      widget.userId ??
      (Get.isRegistered<ExerciseController>()
          ? Get.find<ExerciseController>().userId
          : FirebaseAuth.instance.currentUser!.uid);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final todayKey = ExerciseRepository.dayKeyFromDate(DateTime.now());
    _selectedDays = {
      for (final day in ExerciseRepository.weekDayKeys) day: day == todayKey,
    };
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _planNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _loading = true);
    try {
      final results = await _repository.searchExercises(
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
    final theme = Theme.of(context);
    final isSearching =
        _searchController.text.isNotEmpty || selectedCategory != 'Tümü';

    return Scaffold(
      appBar: const FittaAppBar(title: 'Plan Düzenle'),
      body: RefreshIndicator(
        onRefresh: _loadExercises,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: categories
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: selectedCategory == c,
                                onSelected: (_) {
                                  setState(() => selectedCategory = c);
                                  _loadExercises();
                                },
                              ),
                            ),
                          )
                          .toList(),
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
                  if (isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('Listede yok mu?'),
                          const Spacer(),
                          OutlinedButton.icon(
                            icon: const Icon(CupertinoIcons.pencil),
                            label: const Text('Manuel ekle'),
                            onPressed: _openManualAddSheet,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Plan ismi (opsiyonel)'),
                        TextField(
                          controller: _planNameController,
                          decoration: const InputDecoration(
                            hintText: 'Örn: Push/Pull/Legs',
                          ),
                        ),
                        AppSpacing.vSm,
                        const Text('Günler'),
                        Wrap(
                          spacing: 8,
                          children: ExerciseRepository.weekDayKeys.map((day) {
                            final label = ExerciseRepository.weekDayLabels[day] ??
                                day.toUpperCase();
                            final selected = _selectedDays[day] ?? false;
                            return FilterChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (val) =>
                                  setState(() => _selectedDays[day] = val),
                            );
                          }).toList(),
                        ),
                      ],
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
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Egzersiz bulunamadı'),
                        AppSpacing.vSm,
                        OutlinedButton.icon(
                          icon: const Icon(CupertinoIcons.pencil),
                          label: const Text('Manuel ekle'),
                          onPressed: _openManualAddSheet,
                        ),
                      ],
                    ),
                  ),
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
                              icon:
                                  const Icon(CupertinoIcons.add_circled_solid),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(CupertinoIcons.square_list,
                                    size: 48, color: Colors.grey),
                                AppSpacing.vSm,
                                Text(
                                  'Planınız boş.\nEgzersiz arayarak eklemeye başlayın.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Text(
                            isSearching
                                ? 'Plana eklenenler (${_planned.length})'
                                : 'Plan İçeriği (${_planned.length})',
                            style: Theme.of(context).textTheme.titleMedium),
                        AppSpacing.vSm,
                        ..._planned.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FittaCard(
                              child: ListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                  p.type == 'time'
                                      ? '${p.category} • ${p.sets} x ${p.seconds ?? p.reps} sn'
                                      : '${p.category} • ${p.sets} x ${p.reps}',
                                ),
                                onTap: () => _openEditPlannedSheet(p),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.pencil),
                                      onPressed: () => _openEditPlannedSheet(p),
                                    ),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.trash),
                                      onPressed: () => setState(
                                        () => _planned.removeWhere(
                                            (e) => e.exerciseId == p.exerciseId),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
          label: _saving ? 'Kaydediliyor...' : 'Planı Kaydet',
          icon: const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
          onPressed: _saving ? null : _savePlan,
        ),
      ),
    );
  }

  Future<void> _openBottomSheet(Exercise exercise) async {
    final setsController = TextEditingController(text: '4');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '40');
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
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ağırlık (kg)'),
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
                    weight: weightController.text,
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

  Future<void> _openEditPlannedSheet(PlannedExercise planned) async {
    final setsController = TextEditingController(text: planned.sets.toString());
    final repsValue = planned.type == 'time'
        ? (planned.seconds ?? planned.reps)
        : planned.reps;
    final repsController = TextEditingController(text: repsValue.toString());
    final weightController = TextEditingController(
      text: planned.weight?.toStringAsFixed(1) ?? '',
    );
    String type = planned.type;

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
              Text(planned.name, style: Theme.of(context).textTheme.titleMedium),
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
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ağırlık (kg)'),
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
                label: 'Güncelle',
                onPressed: () {
                  Get.back();
                  final exercise = Exercise(
                    id: planned.exerciseId,
                    name: planned.name,
                    category: planned.category,
                    type: planned.type,
                    description: planned.description,
                  );
                  _addPlannedExercise(
                    exercise: exercise,
                    sets: setsController.text,
                    reps: repsController.text,
                    weight: weightController.text,
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

  Future<void> _openManualAddSheet() async {
    final nameController = TextEditingController();
    final categoryController =
        TextEditingController(text: selectedCategory == 'Tümü' ? '' : selectedCategory);
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '12');
    final weightController = TextEditingController(text: '20');
    final descriptionController = TextEditingController();
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Manuel egzersiz ekle', style: Theme.of(context).textTheme.titleMedium),
                    AppSpacing.vMd,
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Egzersiz adı'),
                    ),
                    AppSpacing.vSm,
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    AppSpacing.vSm,
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                      maxLines: 2,
                    ),
                    AppSpacing.vSm,
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
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ağırlık (kg)'),
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
                      onChanged: (val) => setState(() => type = val ?? 'weight'),
                    ),
                    AppSpacing.vMd,
                    PrimaryButton(
                      label: 'Ekle',
                      onPressed: () {
                        final name = nameController.text.trim();
                        final category = categoryController.text.trim();
                        final description = descriptionController.text.trim();
                        final exercise = Exercise(
                          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                          name: name.isEmpty ? 'Yeni Egzersiz' : name,
                          category: category.isEmpty ? 'Genel' : category,
                          type: type,
                          description: description.isEmpty ? null : description,
                        );
                        Get.back();
                        _addPlannedExercise(
                          exercise: exercise,
                          sets: setsController.text,
                          reps: repsController.text,
                          weight: weightController.text,
                          type: type,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _addPlannedExercise({
    required Exercise exercise,
    required String sets,
    required String reps,
    required String weight,
    required String type,
  }) {
    final parsedSets = int.tryParse(sets) ?? 0;
    final parsedReps = int.tryParse(reps) ?? 0;
    final parsedWeight = double.tryParse(weight);
    final seconds = type == 'time' ? parsedReps : null;
    final planned = PlannedExercise(
      exerciseId: exercise.id,
      name: exercise.name,
      category: exercise.category,
      description: exercise.description,
      sets: parsedSets,
      reps: type == 'time' ? 0 : parsedReps,
      weight: parsedWeight,
      seconds: seconds,
      type: type,
    );
    setState(() {
      final existingIndex = _planned.indexWhere((p) => p.exerciseId == exercise.id);
      if (existingIndex >= 0) {
        _planned[existingIndex] = planned;
      } else {
        _planned.add(planned);
      }
    });
    Get.snackbar('Plan', '${exercise.name} plana eklendi', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _savePlan() async {
    final chosenDays =
        _selectedDays.entries.where((e) => e.value).map((e) => e.key).toList(growable: false);
    if (chosenDays.isEmpty) {
      Get.snackbar('Uyarı', 'Lütfen en az bir gün seçin', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_planned.isEmpty) {
      Get.snackbar('Uyarı', 'Plan boş. Egzersiz ekleyin.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _planNameController.text.trim();
      await _repository.savePlanForDays(
        userId: _userId,
        dayKeys: chosenDays,
        exercises: _planned,
        planName: name.isEmpty ? null : name,
      );
      Get.snackbar('Başarılı', 'Plan kaydedildi', snackPosition: SnackPosition.BOTTOM);
      if (Get.isRegistered<ExerciseController>()) {
        final ctrl = Get.find<ExerciseController>();
        await ctrl.changeDay(chosenDays.first, forceReload: true);
      }
    } catch (e) {
      Get.snackbar('Hata', 'Plan kaydedilemedi: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
