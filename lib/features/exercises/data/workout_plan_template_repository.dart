import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workout_plan_template.dart';

class WorkoutPlanTemplateRepository {
  WorkoutPlanTemplateRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _templates(String userId) =>
      firestore.collection('users').doc(userId).collection('planTemplates');

  Future<void> savePlanTemplate({
    required String userId,
    required WorkoutPlanTemplate template,
  }) async {
    final ref = template.id.isEmpty
        ? _templates(userId).doc()
        : _templates(userId).doc(template.id);
    final data = template.toMap();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deletePlanTemplate({
    required String userId,
    required String templateId,
  }) async {
    await _templates(userId).doc(templateId).delete();
  }

  Stream<List<WorkoutPlanTemplate>> watchPlanTemplates(String userId) {
    return _templates(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WorkoutPlanTemplate.fromMap(doc.id, doc.data()))
            .toList());
  }
}
