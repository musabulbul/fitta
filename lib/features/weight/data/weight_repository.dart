import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/weight_entry.dart';

class WeightRepository {
  WeightRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _entries(String userId) =>
      firestore.collection('users').doc(userId).collection('bodyStats');

  Future<WeightEntry?> getLastEntry(String userId) async {
    final snap =
        await _entries(userId).orderBy('date', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return WeightEntry.fromMap({'id': doc.id, ...doc.data()});
  }

  Future<void> addEntry(String userId, WeightEntry entry) async {
    final ref = entry.id.isNotEmpty ? _entries(userId).doc(entry.id) : _entries(userId).doc();
    await ref.set(entry.toMap());
  }

  Stream<List<WeightEntry>> watchEntries(String userId) {
    return _entries(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WeightEntry.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }
}
