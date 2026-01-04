import 'package:cloud_firestore/cloud_firestore.dart';

import 'planned_exercise.dart';

class WorkoutPlanTemplate {
  const WorkoutPlanTemplate({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final List<PlannedExercise> exercises;
  final DateTime createdAt;

  WorkoutPlanTemplate copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    List<PlannedExercise>? exercises,
    DateTime? createdAt,
  }) {
    return WorkoutPlanTemplate(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkoutPlanTemplate.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutPlanTemplate(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      name: map['name'] as String? ?? 'İsimsiz Plan',
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => PlannedExercise.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
