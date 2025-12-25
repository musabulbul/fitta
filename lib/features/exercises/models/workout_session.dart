import 'package:cloud_firestore/cloud_firestore.dart';

import 'workout_exercise_log.dart';

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.date,
    this.planId,
    this.exercises = const [],
  });

  final String id;
  final DateTime date;
  final String? planId;
  final List<WorkoutExerciseLog> exercises;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'planId': planId,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as String? ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      planId: map['planId'] as String?,
      exercises: ((map['exercises'] as List?) ?? [])
          .map((e) => WorkoutExerciseLog.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    String? planId,
    List<WorkoutExerciseLog>? exercises,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      planId: planId ?? this.planId,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  String toString() =>
      'WorkoutSession(id: $id, date: $date, planId: $planId, exercises: ${exercises.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSession &&
        other.id == id &&
        other.date == date &&
        other.planId == planId &&
        _listEquals(other.exercises, exercises);
  }

  @override
  int get hashCode =>
      Object.hash(id, date, planId, Object.hashAll(exercises.map((e) => e.hashCode)));

  bool _listEquals(List<WorkoutExerciseLog> a, List<WorkoutExerciseLog> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
