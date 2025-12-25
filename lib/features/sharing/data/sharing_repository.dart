import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client_link.dart';
import '../models/share_permission.dart';

class SharingRepository {
  SharingRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _sharedWith(String ownerUserId) =>
      firestore.collection('users').doc(ownerUserId).collection('sharedWith');

  CollectionReference<Map<String, dynamic>> _clients(String trainerUserId) =>
      firestore.collection('users').doc(trainerUserId).collection('clients');

  /// Finds a userId by email. Tries root users documents and profile subcollection.
  Future<String?> findUserIdByEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // Try root users collection (email stored on user doc).
    final rootQuery =
        await firestore.collection('users').where('email', isEqualTo: trimmed).limit(1).get();
    if (rootQuery.docs.isNotEmpty) {
      return rootQuery.docs.first.id;
    }

    // Try collection group on profile docs.
    final profileQuery = await firestore
        .collectionGroup('profile')
        .where('email', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (profileQuery.docs.isNotEmpty) {
      final doc = profileQuery.docs.first;
      // parent path: users/{userId}/profile
      final segments = doc.reference.path.split('/');
      final userIndex = segments.indexOf('users');
      if (userIndex >= 0 && userIndex + 1 < segments.length) {
        return segments[userIndex + 1];
      }
    }
    return null;
  }

  Future<void> addSharePermission({
    required String ownerUserId,
    required String targetUserId,
    required String role, // trainer | viewer
  }) async {
    final sharedWithRef = _sharedWith(ownerUserId).doc(targetUserId);
    final clientRef = _clients(targetUserId).doc(ownerUserId);

    await firestore.runTransaction((txn) async {
      txn.set(sharedWithRef, {
        'ownerUserId': ownerUserId,
        'targetUserId': targetUserId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.set(clientRef, {
        'ownerUserId': ownerUserId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeSharePermission({
    required String ownerUserId,
    required String targetUserId,
  }) async {
    final sharedWithRef = _sharedWith(ownerUserId).doc(targetUserId);
    final clientRef = _clients(targetUserId).doc(ownerUserId);

    final batch = firestore.batch();
    batch.delete(sharedWithRef);
    batch.delete(clientRef);
    await batch.commit();
  }

  Stream<List<SharePermission>> watchSharedWith(String ownerUserId) {
    return _sharedWith(ownerUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SharePermission.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<ClientLink>> watchClients(String trainerUserId) {
    return _clients(trainerUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ClientLink.fromMap(doc.id, doc.data())).toList());
  }
}
