import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_package.dart';

class PackageRepository {
  PackageRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _packages(String userId) =>
      firestore.collection('users').doc(userId).collection('packages');

  Future<void> savePackage({
    required String userId,
    required WorkoutPackage package,
  }) async {
    final ref = _packages(userId).doc(package.id.isEmpty ? null : package.id);
    final data = package.toMap();
    // If id was empty, new doc created, update local model or let stream handle it
    if (package.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deletePackage({required String userId, required String packageId}) async {
    await _packages(userId).doc(packageId).delete();
  }

  Stream<List<WorkoutPackage>> watchPackages(String userId) {
    return _packages(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WorkoutPackage.fromMap(doc.id, doc.data()))
            .toList());
  }
}
