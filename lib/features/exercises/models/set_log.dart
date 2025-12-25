class SetLog {
  const SetLog({
    required this.setNo,
    required this.reps,
    this.weight,
    this.seconds,
  });

  final int setNo;
  final int reps;
  final double? weight;
  final int? seconds;

  SetLog copyWith({
    int? setNo,
    int? reps,
    double? weight,
    int? seconds,
  }) {
    return SetLog(
      setNo: setNo ?? this.setNo,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      seconds: seconds ?? this.seconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNo': setNo,
      'reps': reps,
      'weight': weight,
      'seconds': seconds,
    };
  }

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      setNo: (map['setNo'] as num?)?.toInt() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      seconds: (map['seconds'] as num?)?.toInt(),
    );
  }

  @override
  String toString() => 'SetLog(setNo: $setNo, reps: $reps, weight: $weight, seconds: $seconds)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetLog &&
        other.setNo == setNo &&
        other.reps == reps &&
        other.weight == weight &&
        other.seconds == seconds;
  }

  @override
  int get hashCode => Object.hash(setNo, reps, weight, seconds);
}
