import 'package:cloud_firestore/cloud_firestore.dart';
import '../../exercises/models/planned_exercise.dart';

class WorkoutPackage {
  const WorkoutPackage({
    required this.id,
    required this.ownerUserId,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    this.tags = const [],
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String? description;
  final List<PlannedExercise> exercises;
  final DateTime createdAt;
  final List<String> tags;

  WorkoutPackage copyWith({
    String? id,
    String? ownerUserId,
    String? name,
    String? description,
    List<PlannedExercise>? exercises,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return WorkoutPackage(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
    };
  }

  factory WorkoutPackage.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutPackage(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      name: map['name'] as String? ?? 'İsimsiz Paket',
      description: map['description'] as String?,
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => PlannedExercise.fromMap(e))
              .toList() ??
          [],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
