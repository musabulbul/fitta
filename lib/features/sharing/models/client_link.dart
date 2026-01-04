import 'package:cloud_firestore/cloud_firestore.dart';

class ClientLink {
  const ClientLink({
    required this.id,
    required this.ownerUserId,
    required this.role,
    required this.createdAt,
    required this.ownerDisplayName,
    required this.ownerEmail,
    required this.ownerPhotoUrl,
    required this.sharePhoto,
    required this.shareWorkouts,
    required this.shareWeight,
    required this.shareMeasurements,
  });

  final String id;
  final String ownerUserId; // the client / data owner
  final String role; // trainer | viewer
  final DateTime createdAt;
  final String ownerDisplayName;
  final String ownerEmail;
  final String ownerPhotoUrl;
  final bool sharePhoto;
  final bool shareWorkouts;
  final bool shareWeight;
  final bool shareMeasurements;

  ClientLink copyWith({
    String? id,
    String? ownerUserId,
    String? role,
    DateTime? createdAt,
    String? ownerDisplayName,
    String? ownerEmail,
    String? ownerPhotoUrl,
    bool? sharePhoto,
    bool? shareWorkouts,
    bool? shareWeight,
    bool? shareMeasurements,
  }) {
    return ClientLink(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      sharePhoto: sharePhoto ?? this.sharePhoto,
      shareWorkouts: shareWorkouts ?? this.shareWorkouts,
      shareWeight: shareWeight ?? this.shareWeight,
      shareMeasurements: shareMeasurements ?? this.shareMeasurements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerDisplayName': ownerDisplayName,
      'ownerEmail': ownerEmail,
      'ownerPhotoUrl': ownerPhotoUrl,
      'permissions': {
        'photo': sharePhoto,
        'workouts': shareWorkouts,
        'weight': shareWeight,
        'measurements': shareMeasurements,
      },
    };
  }

  factory ClientLink.fromMap(String id, Map<String, dynamic> map) {
    final permissions = map['permissions'] as Map<String, dynamic>?;
    return ClientLink(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      role: map['role'] as String? ?? 'trainer',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      ownerDisplayName: map['ownerDisplayName'] as String? ?? '',
      ownerEmail: map['ownerEmail'] as String? ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String? ?? '',
      sharePhoto: _readPermission(permissions, 'photo'),
      shareWorkouts: _readPermission(permissions, 'workouts'),
      shareWeight: _readPermission(permissions, 'weight'),
      shareMeasurements: _readPermission(permissions, 'measurements'),
    );
  }

  static bool _readPermission(Map<String, dynamic>? permissions, String key) {
    if (permissions == null) return true;
    final value = permissions[key];
    if (value is bool) return value;
    return true;
  }
}
