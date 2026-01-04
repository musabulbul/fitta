import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../data/exercise_repository.dart';
import '../data/workout_plan_template_repository.dart';
import '../models/workout_plan_template.dart';

class WorkoutPlanTemplateController extends GetxController {
  WorkoutPlanTemplateController({
    required this.repository,
    required this.exerciseRepository,
    String? userId,
  }) : userId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  final WorkoutPlanTemplateRepository repository;
  final ExerciseRepository exerciseRepository;
  final String userId;

  final templates = <WorkoutPlanTemplate>[].obs;
  final dayAssignments = <String, String?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    templates.bindStream(repository.watchPlanTemplates(userId));
    dayAssignments.bindStream(exerciseRepository.watchTemplateAssignments(userId));
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await repository.deletePlanTemplate(userId: userId, templateId: templateId);
      Get.snackbar('Başarılı', 'Plan silindi');
    } catch (e) {
      Get.snackbar('Hata', 'Plan silinemedi: $e');
    }
  }
}
