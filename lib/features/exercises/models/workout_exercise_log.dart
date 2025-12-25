import 'set_log.dart';

class WorkoutExerciseLog {
  const WorkoutExerciseLog({
    required this.exerciseId,
    required this.name,
    required this.plannedSets,
    required this.plannedReps,
    this.plannedWeight,
    this.plannedSeconds,
    this.logs = const [],
  });

  final String exerciseId;
  final String name;
  final int plannedSets;
  final int plannedReps;
  final double? plannedWeight;
  final int? plannedSeconds;
  final List<SetLog> logs;

  WorkoutExerciseLog copyWith({
    String? exerciseId,
    String? name,
    int? plannedSets,
    int? plannedReps,
    double? plannedWeight,
    int? plannedSeconds,
    List<SetLog>? logs,
  }) {
    return WorkoutExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      plannedSets: plannedSets ?? this.plannedSets,
      plannedReps: plannedReps ?? this.plannedReps,
      plannedWeight: plannedWeight ?? this.plannedWeight,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'plannedSets': plannedSets,
      'plannedReps': plannedReps,
      'plannedWeight': plannedWeight,
      'plannedSeconds': plannedSeconds,
      'logs': logs.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutExerciseLog.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseLog(
      exerciseId: map['exerciseId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      plannedSets: (map['plannedSets'] as num?)?.toInt() ?? 0,
      plannedReps: (map['plannedReps'] as num?)?.toInt() ?? 0,
      plannedWeight: (map['plannedWeight'] as num?)?.toDouble(),
      plannedSeconds: (map['plannedSeconds'] as num?)?.toInt(),
      logs: ((map['logs'] as List?) ?? [])
          .map((e) => SetLog.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  String toString() =>
      'WorkoutExerciseLog(exerciseId: $exerciseId, name: $name, plannedSets: $plannedSets, plannedReps: $plannedReps, plannedWeight: $plannedWeight, plannedSeconds: $plannedSeconds, logs: $logs)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExerciseLog &&
        other.exerciseId == exerciseId &&
        other.name == name &&
        other.plannedSets == plannedSets &&
        other.plannedReps == plannedReps &&
        other.plannedWeight == plannedWeight &&
        other.plannedSeconds == plannedSeconds &&
        _listEquals(other.logs, logs);
  }

  @override
  int get hashCode => Object.hash(exerciseId, name, plannedSets, plannedReps,
      plannedWeight, plannedSeconds, Object.hashAll(logs));

  bool _listEquals(List<SetLog> a, List<SetLog> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
