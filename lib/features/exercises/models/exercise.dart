import 'package:flutter/foundation.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    this.keywords = const [],
    this.imagePath,
    this.description,
  });

  final String id;
  final String name;
  final String category;
  final String type; // weight | time | reps
  final List<String> keywords;
  final String? imagePath;
  final String? description;

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    List<String>? keywords,
    String? imagePath,
    String? description,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      keywords: keywords ?? this.keywords,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'type': type,
      'keywords': keywords,
      'imagePath': imagePath,
      'description': description,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      type: map['type'] as String? ?? 'weight',
      keywords: (map['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      imagePath: map['imagePath'] as String?,
      description: map['description'] as String?,
    );
  }

  factory Exercise.fromDoc(String id, Map<String, dynamic> map) {
    return Exercise.fromMap({'id': id, ...map});
  }

  @override
  String toString() =>
      'Exercise(id: $id, name: $name, category: $category, type: $type, keywords: $keywords, imagePath: $imagePath, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.type == type &&
        other.imagePath == imagePath &&
        other.description == description &&
        listEquals(other.keywords, keywords);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, type, imagePath, description, Object.hashAll(keywords));
}
