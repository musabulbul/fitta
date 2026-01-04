import 'package:cloud_firestore/cloud_firestore.dart';

class SharePermission {
  const SharePermission({
    required this.id,
    required this.ownerUserId,
    required this.targetUserId,
    required this.targetDisplayName,
    required this.targetEmail,
    required this.role,
    required this.createdAt,
    required this.sharePhoto,
    required this.shareWorkouts,
    required this.shareWeight,
    required this.shareMeasurements,
  });

  final String id;
  final String ownerUserId;
  final String targetUserId;
  final String targetDisplayName;
  final String targetEmail;
  final String role; // trainer | viewer
  final DateTime createdAt;
  final bool sharePhoto;
  final bool shareWorkouts;
  final bool shareWeight;
  final bool shareMeasurements;

  SharePermission copyWith({
    String? id,
    String? ownerUserId,
    String? targetUserId,
    String? targetDisplayName,
    String? targetEmail,
    String? role,
    DateTime? createdAt,
    bool? sharePhoto,
    bool? shareWorkouts,
    bool? shareWeight,
    bool? shareMeasurements,
  }) {
    return SharePermission(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      targetUserId: targetUserId ?? this.targetUserId,
      targetDisplayName: targetDisplayName ?? this.targetDisplayName,
      targetEmail: targetEmail ?? this.targetEmail,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      sharePhoto: sharePhoto ?? this.sharePhoto,
      shareWorkouts: shareWorkouts ?? this.shareWorkouts,
      shareWeight: shareWeight ?? this.shareWeight,
      shareMeasurements: shareMeasurements ?? this.shareMeasurements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'targetUserId': targetUserId,
      'targetDisplayName': targetDisplayName,
      'targetEmail': targetEmail,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'permissions': {
        'photo': sharePhoto,
        'workouts': shareWorkouts,
        'weight': shareWeight,
        'measurements': shareMeasurements,
      },
    };
  }

  factory SharePermission.fromMap(String id, Map<String, dynamic> map) {
    final permissions = map['permissions'] as Map<String, dynamic>?;
    return SharePermission(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      targetUserId: map['targetUserId'] as String? ?? '',
      targetDisplayName: map['targetDisplayName'] as String? ?? '',
      targetEmail: map['targetEmail'] as String? ?? '',
      role: map['role'] as String? ?? 'viewer',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
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
