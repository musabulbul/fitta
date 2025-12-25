import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/measurement_entry.dart';

class MeasurementRepository {
  MeasurementRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _entries(String userId) =>
      firestore.collection('users').doc(userId).collection('measurements');

  Future<MeasurementEntry?> getLastEntry(String userId) async {
    final snap =
        await _entries(userId).orderBy('date', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return MeasurementEntry.fromMap({...doc.data(), 'id': doc.id});
  }

  Future<MeasurementEntry?> getEntryByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snap = await _entries(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return MeasurementEntry.fromMap({...doc.data(), 'id': doc.id});
  }

  Future<void> addEntry(String userId, MeasurementEntry entry) async {
    final ref = entry.id.isNotEmpty ? _entries(userId).doc(entry.id) : _entries(userId).doc();
    await ref.set(entry.toMap());
  }

  Stream<List<MeasurementEntry>> watchEntries(String userId) {
    return _entries(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MeasurementEntry.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
