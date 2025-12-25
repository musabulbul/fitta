import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import '../controllers/exercise_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/exercise_repository.dart';
import '../models/set_log.dart';
import '../models/workout_exercise_log.dart';
import '../models/workout_session.dart';

enum _ChartMetric {
  weight,
  seconds,
  reps,
}

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

  _ChartMetric _detectMetric(List<WorkoutSession> sessions) {
    var hasWeight = false;
    var hasSeconds = false;
    for (final session in sessions) {
      final exercise = _findExerciseLog(session);
      if (exercise == null) continue;
      if (exercise.plannedWeight != null ||
          exercise.logs.any((log) => log.weight != null)) {
        hasWeight = true;
      }
      if (exercise.plannedSeconds != null ||
          exercise.logs.any((log) => log.seconds != null)) {
        hasSeconds = true;
      }
    }
    if (hasWeight) return _ChartMetric.weight;
    if (hasSeconds) return _ChartMetric.seconds;
    return _ChartMetric.reps;
  }

  WorkoutExerciseLog? _findExerciseLog(WorkoutSession session) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseId == widget.exerciseId) return exercise;
    }
    return null;
  }

  double _metricValue(WorkoutExerciseLog exercise, _ChartMetric metric) {
    switch (metric) {
      case _ChartMetric.weight:
        final weights = exercise.logs.map((l) => l.weight).whereType<double>().toList();
        return _averageDoubles(weights, fallback: exercise.plannedWeight);
      case _ChartMetric.seconds:
        final seconds = exercise.logs.map((l) => l.seconds).whereType<int>().toList();
        return _averageInts(seconds, fallback: exercise.plannedSeconds);
      case _ChartMetric.reps:
        final reps = exercise.logs.map((l) => l.reps).toList();
        return _averageInts(reps, fallback: exercise.plannedReps);
    }
  }

  double _averageDoubles(List<double> values, {double? fallback}) {
    if (values.isEmpty) return fallback ?? 0;
    final total = values.reduce((a, b) => a + b);
    return total / values.length;
  }

  double _averageInts(List<int> values, {int? fallback}) {
    if (values.isEmpty) return (fallback ?? 0).toDouble();
    final total = values.reduce((a, b) => a + b);
    return total / values.length;
  }

  String _metricLabel(_ChartMetric metric) {
    switch (metric) {
      case _ChartMetric.weight:
        return 'kg';
      case _ChartMetric.seconds:
        return 'sn';
      case _ChartMetric.reps:
        return 'tekrar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          final sortedSessions = [...sessions]
            ..sort((a, b) => a.date.compareTo(b.date));
          final metric = _detectMetric(sortedSessions);
          final chartDates = <DateTime>[];
          final chartPoints = <FlSpot>[];
          for (final session in sortedSessions) {
            final exercise = _findExerciseLog(session);
            if (exercise == null) continue;
            chartDates.add(session.date);
            chartPoints.add(FlSpot(chartPoints.length.toDouble(), _metricValue(exercise, metric)));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FittaCard(
                child: SizedBox(
                  height: 220,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: chartPoints.isEmpty
                        ? Center(
                            child: Text(
                              'Grafik için veri yok.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ortalama ${_metricLabel(metric)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    lineTouchData: const LineTouchData(enabled: true),
                                    gridData:
                                        const FlGridData(show: true, drawVerticalLine: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 1,
                                          getTitlesWidget: (val, meta) {
                                            final index = val.toInt();
                                            if (index < 0 || index >= chartDates.length) {
                                              return const SizedBox();
                                            }
                                            if (chartDates.length > 5) {
                                              final step = (chartDates.length / 5).ceil();
                                              if (index % step != 0) return const SizedBox();
                                            }
                                            final date = chartDates[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: chartPoints,
                                        isCurved: true,
                                        color: theme.colorScheme.primary,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
            _formatDateTime(session.date),
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

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} • $hour:$minute';
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
