class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.name,
    required this.category,
    required this.sets,
    required this.reps,
    required this.type,
    this.weight,
    this.seconds,
    this.nextWeight,
    this.description,
  });

  final String exerciseId;
  final String name;
  final String category;
  final int sets;
  final int reps;
  final double? weight;
  final int? seconds;
  final String type; // weight | time | reps
  final double? nextWeight;
  final String? description;

  PlannedExercise copyWith({
    String? exerciseId,
    String? name,
    String? category,
    int? sets,
    int? reps,
    double? weight,
    int? seconds,
    String? type,
    double? nextWeight,
    String? description,
  }) {
    return PlannedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      seconds: seconds ?? this.seconds,
      type: type ?? this.type,
      nextWeight: nextWeight ?? this.nextWeight,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'category': category,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'seconds': seconds,
      'type': type,
      'nextWeight': nextWeight,
      'description': description,
    };
  }

  factory PlannedExercise.fromMap(Map<String, dynamic> map) {
    return PlannedExercise(
      exerciseId: map['exerciseId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      sets: (map['sets'] as num?)?.toInt() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      seconds: (map['seconds'] as num?)?.toInt(),
      type: map['type'] as String? ?? 'weight',
      nextWeight: (map['nextWeight'] as num?)?.toDouble(),
      description: map['description'] as String?,
    );
  }

  @override
  String toString() =>
      'PlannedExercise(exerciseId: $exerciseId, name: $name, category: $category, sets: $sets, reps: $reps, weight: $weight, seconds: $seconds, type: $type, nextWeight: $nextWeight, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannedExercise &&
        other.exerciseId == exerciseId &&
        other.name == name &&
        other.category == category &&
        other.sets == sets &&
        other.reps == reps &&
        other.weight == weight &&
        other.seconds == seconds &&
        other.type == type &&
        other.nextWeight == nextWeight &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(
        exerciseId,
        name,
        category,
        sets,
        reps,
        weight,
        seconds,
        type,
        nextWeight,
        description,
      );
}
