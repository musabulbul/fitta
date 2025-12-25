import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementEntry {
  const MeasurementEntry({
    required this.id,
    required this.date,
    this.chest,
    this.waist,
    this.hip,
    this.biceps,
    this.thigh,
    this.calf,
  });

  final String id;
  final DateTime date;
  final double? chest;
  final double? waist;
  final double? hip;
  final double? biceps;
  final double? thigh;
  final double? calf;

  MeasurementEntry copyWith({
    String? id,
    DateTime? date,
    double? chest,
    double? waist,
    double? hip,
    double? biceps,
    double? thigh,
    double? calf,
  }) {
    return MeasurementEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      biceps: biceps ?? this.biceps,
      thigh: thigh ?? this.thigh,
      calf: calf ?? this.calf,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'biceps': biceps,
      'thigh': thigh,
      'calf': calf,
    };
  }

  factory MeasurementEntry.fromMap(Map<String, dynamic> map) {
    return MeasurementEntry(
      id: map['id'] as String? ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      chest: (map['chest'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      biceps: (map['biceps'] as num?)?.toDouble(),
      thigh: (map['thigh'] as num?)?.toDouble(),
      calf: (map['calf'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'MeasurementEntry(id: $id, date: $date, chest: $chest, waist: $waist, hip: $hip, biceps: $biceps, thigh: $thigh, calf: $calf)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementEntry &&
        other.id == id &&
        other.date == date &&
        other.chest == chest &&
        other.waist == waist &&
        other.hip == hip &&
        other.biceps == biceps &&
        other.thigh == thigh &&
        other.calf == calf;
  }

  @override
  int get hashCode => Object.hash(id, date, chest, waist, hip, biceps, thigh, calf);
}
