import 'package:cloud_firestore/cloud_firestore.dart';

class SharePermission {
  const SharePermission({
    required this.id,
    required this.ownerUserId,
    required this.targetUserId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId;
  final String targetUserId;
  final String role; // trainer | viewer
  final DateTime createdAt;

  SharePermission copyWith({
    String? id,
    String? ownerUserId,
    String? targetUserId,
    String? role,
    DateTime? createdAt,
  }) {
    return SharePermission(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      targetUserId: targetUserId ?? this.targetUserId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'targetUserId': targetUserId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SharePermission.fromMap(String id, Map<String, dynamic> map) {
    return SharePermission(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      targetUserId: map['targetUserId'] as String? ?? '',
      role: map['role'] as String? ?? 'viewer',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
