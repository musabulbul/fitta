import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import '../controllers/exercise_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/exercise_repository.dart';
import '../models/set_log.dart';
import '../models/workout_exercise_log.dart';
import '../models/workout_session.dart';

class ExerciseHistoryPage extends StatefulWidget {
  const ExerciseHistoryPage({
    super.key,
    required this.exerciseId,
    this.exerciseName,
    this.repository,
  });

  final String exerciseId;
  final String? exerciseName;
  final ExerciseRepository? repository;

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  late final ExerciseRepository repository;
  late Future<List<WorkoutSession>> _future;

  String get _userId =>
      Get.isRegistered<ExerciseController>()
          ? Get.find<ExerciseController>().userId
          : (FirebaseAuth.instance.currentUser?.uid ?? 'demoUser');

  @override
  void initState() {
    super.initState();
    repository = widget.repository ??
        (Get.isRegistered<ExerciseController>()
            ? Get.find<ExerciseController>().repository
            : ExerciseRepository());
    _future = _load();
  }

  Future<List<WorkoutSession>> _load() {
    return repository.getExerciseHistory(userId: _userId, exerciseId: widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FittaAppBar(title: 'Geçmiş - ${widget.exerciseName ?? widget.exerciseId}'),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return const Center(child: Text('Geçmiş bulunamadı.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FittaCard(
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Grafik gelecek',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              AppSpacing.vMd,
              ...sessions.map(
                (session) => _HistoryTile(
                  session: session,
                  exerciseId: widget.exerciseId,
                  onDelete: () async {
                    await repository.deleteWorkoutSession(userId: _userId, sessionId: session.id);
                    setState(() {
                      _future = _load();
                    });
                    Get.snackbar('Silindi', 'Kayıt silindi', snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.exerciseId,
    required this.onDelete,
  });

  final WorkoutSession session;
  final String exerciseId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    WorkoutExerciseLog? exercise;
    for (final e in session.exercises) {
      if (e.exerciseId == exerciseId) {
        exercise = e;
        break;
      }
    }
    exercise ??= session.exercises.isNotEmpty ? session.exercises.first : null;
    final logs = exercise?.logs ?? [];
    final totalSets = logs.isNotEmpty ? logs.length : (exercise?.plannedSets ?? 0);
    final averageWeight = _averageWeight(logs, fallback: exercise?.plannedWeight);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FittaCard(
        child: ListTile(
          title: Text(
            _formatDate(session.date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text('Toplam set: $totalSets • Ortalama ağırlık: $averageWeight kg'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.trash),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Silinsin mi?'),
                          content: const Text('Bu gün için kayıt silinecek.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) onDelete();
                },
              ),
              const Icon(CupertinoIcons.time),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  double _averageWeight(List<SetLog> logs, {double? fallback}) {
    final weights = logs.map((l) => l.weight).whereType<double>().toList();
    if (weights.isEmpty) {
      return double.parse((fallback ?? 0).toStringAsFixed(1));
    }
    final total = weights.reduce((a, b) => a + b);
    return double.parse((total / weights.length).toStringAsFixed(1));
  }
}
