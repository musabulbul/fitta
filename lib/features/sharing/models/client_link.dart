import 'package:cloud_firestore/cloud_firestore.dart';

class ClientLink {
  const ClientLink({
    required this.id,
    required this.ownerUserId,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String ownerUserId; // the client / data owner
  final String role; // trainer | viewer
  final DateTime createdAt;

  ClientLink copyWith({
    String? id,
    String? ownerUserId,
    String? role,
    DateTime? createdAt,
  }) {
    return ClientLink(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClientLink.fromMap(String id, Map<String, dynamic> map) {
    return ClientLink(
      id: id,
      ownerUserId: map['ownerUserId'] as String? ?? '',
      role: map['role'] as String? ?? 'trainer',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
