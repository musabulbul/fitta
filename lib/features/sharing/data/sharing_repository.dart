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

    // Try collection group on profile docs (best-effort; may be blocked by rules).
    try {
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
    } catch (_) {
      // Ignore if profile collection is not readable for this user.
    }
    return null;
  }

  Future<void> addSharePermission({
    required String ownerUserId,
    required String targetUserId,
    required String ownerEmail,
    required String targetDisplayName,
    required String targetEmail,
    required String role, // trainer | viewer
    required bool sharePhoto,
    required bool shareWorkouts,
    required bool shareWeight,
    required bool shareMeasurements,
    required String ownerDisplayName,
    required String ownerPhotoUrl,
  }) async {
    final sharedWithRef = _sharedWith(ownerUserId).doc(targetUserId);
    final clientRef = _clients(targetUserId).doc(ownerUserId);

    await firestore.runTransaction((txn) async {
      txn.set(sharedWithRef, {
        'ownerUserId': ownerUserId,
        'targetUserId': targetUserId,
        'targetDisplayName': targetDisplayName,
        'targetEmail': targetEmail,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': {
          'photo': sharePhoto,
          'workouts': shareWorkouts,
          'weight': shareWeight,
          'measurements': shareMeasurements,
        },
      });
      txn.set(clientRef, {
        'ownerUserId': ownerUserId,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerDisplayName': ownerDisplayName,
        'ownerEmail': ownerEmail,
        'ownerPhotoUrl': ownerPhotoUrl,
        'permissions': {
          'photo': sharePhoto,
          'workouts': shareWorkouts,
          'weight': shareWeight,
          'measurements': shareMeasurements,
        },
      });
    });
  }

  Future<Map<String, String>> getUserSummary(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      return {
        'displayName': (data['displayName'] as String?) ?? '',
        'email': (data['email'] as String?) ?? '',
      };
    } catch (_) {
      return {
        'displayName': '',
        'email': '',
      };
    }
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
        .asyncMap((snap) async {
          final items = await Future.wait(snap.docs.map((doc) async {
            final share = SharePermission.fromMap(doc.id, doc.data());
            if (share.targetDisplayName.isNotEmpty && share.targetEmail.isNotEmpty) {
              return share;
            }
            final summary = await getUserSummary(share.targetUserId);
            final displayName = summary['displayName'] ?? share.targetDisplayName;
            final email = summary['email'] ?? share.targetEmail;
            return share.copyWith(
              targetDisplayName: displayName,
              targetEmail: email,
            );
          }));
          return items;
        });
  }

  Stream<List<ClientLink>> watchClients(String trainerUserId) {
    return _clients(trainerUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final items = await Future.wait(snap.docs.map((doc) async {
            final client = ClientLink.fromMap(doc.id, doc.data());
            if (client.ownerDisplayName.isNotEmpty && client.ownerEmail.isNotEmpty) {
              return client;
            }
            final summary = await getUserSummary(client.ownerUserId);
            final displayName = summary['displayName'] ?? client.ownerDisplayName;
            final email = summary['email'] ?? client.ownerEmail;
            return client.copyWith(
              ownerDisplayName: displayName,
              ownerEmail: email,
            );
          }));
          return items;
        });
  }
}
