import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.height,
    this.waist,
    this.hip,
    this.neck,
    this.gender,
    this.bodyFatPercent,
  });

  final String id;
  final DateTime date;
  final double weight;
  final double? height;
  final double? waist;
  final double? hip;
  final double? neck;
  final String? gender; // male | female
  final double? bodyFatPercent;

  WeightEntry copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? height,
    double? waist,
    double? hip,
    double? neck,
    String? gender,
    double? bodyFatPercent,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      neck: neck ?? this.neck,
      gender: gender ?? this.gender,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'waist': waist,
      'hip': hip,
      'neck': neck,
      'gender': gender,
      'bodyFatPercent': bodyFatPercent,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String? ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      height: (map['height'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      bodyFatPercent: (map['bodyFatPercent'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'WeightEntry(id: $id, date: $date, weight: $weight, height: $height, waist: $waist, hip: $hip, neck: $neck, gender: $gender, bodyFat: $bodyFatPercent)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntry &&
        other.id == id &&
        other.date == date &&
        other.weight == weight &&
        other.height == height &&
        other.waist == waist &&
        other.hip == hip &&
        other.neck == neck &&
        other.gender == gender &&
        other.bodyFatPercent == bodyFatPercent;
  }

  @override
  int get hashCode =>
      Object.hash(id, date, weight, height, waist, hip, neck, gender, bodyFatPercent);
}
