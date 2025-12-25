import 'dart:developer';

import 'package:get/get.dart';
import 'package:collection/collection.dart';

import '../data/exercise_repository.dart';
import '../models/planned_exercise.dart';
import '../models/set_log.dart';

class ExerciseController extends GetxController {
  ExerciseController({
    required this.repository,
    required this.userId,
  });

  final ExerciseRepository repository;
  final String userId;

  final isLoading = false.obs;
  final todayPlan = <PlannedExercise>[].obs;
  final planNames = <String, String?>{}.obs;
  final logsByExerciseId = <String, List<SetLog>>{}.obs;
  final nextWeights = <String, double?>{}.obs;
  final selectedDayKey = ExerciseRepository.dayKeyFromDate(DateTime.now()).obs;
  final savedExercises = <String, bool>{}.obs;
  final savingExercises = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlanForSelectedDay();
  }

  Future<void> loadPlanForSelectedDay() async {
    isLoading.value = true;
    try {
      final plan = await repository.getPlanForDay(userId, selectedDayKey.value);
      todayPlan.assignAll(plan.exercises);
      planNames[selectedDayKey.value] = plan.name;
      final validIds = plan.exercises.map((p) => p.exerciseId).toSet();
      logsByExerciseId.removeWhere((key, _) => !validIds.contains(key));
      nextWeights.removeWhere((key, _) => !validIds.contains(key));
      savedExercises.clear();
      savingExercises.clear();
      for (final plan in plan.exercises) {
        nextWeights[plan.exerciseId] =
            plan.type == 'time' ? plan.seconds?.toDouble() : plan.nextWeight ?? plan.weight;
        logsByExerciseId.putIfAbsent(plan.exerciseId, () => <SetLog>[]);
        savedExercises[plan.exerciseId] = false;
        savingExercises[plan.exerciseId] = false;
      }
      final latestSession =
          await repository.getLatestSessionForPlan(userId: userId, planId: selectedDayKey.value);
      if (latestSession != null) {
        for (final ex in latestSession.exercises) {
          savedExercises[ex.exerciseId] = true;
          logsByExerciseId[ex.exerciseId] = ex.logs;
        }
      }
      nextWeights.refresh();
      logsByExerciseId.refresh();
      savedExercises.refresh();
      savingExercises.refresh();
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeDay(String dayKey, {bool forceReload = false}) async {
    if (!forceReload && selectedDayKey.value == dayKey && todayPlan.isNotEmpty) return;
    selectedDayKey.value = dayKey;
    await loadPlanForSelectedDay();
  }

  Future<void> removeExerciseFromToday(String exerciseId) async {
    isLoading.value = true;
    try {
      final updated = todayPlan.where((p) => p.exerciseId != exerciseId).toList();
      final name = planNames[selectedDayKey.value];
      await repository.updatePlanForDay(
        userId: userId,
        dayKey: selectedDayKey.value,
        exercises: updated,
        planName: name,
      );
      todayPlan.assignAll(updated);
      logsByExerciseId.remove(exerciseId);
      nextWeights.remove(exerciseId);
      savedExercises.remove(exerciseId);
      savingExercises.remove(exerciseId);
      nextWeights.refresh();
      logsByExerciseId.refresh();
      savedExercises.refresh();
      savingExercises.refresh();
      Get.snackbar('Başarılı', 'Egzersiz plandan çıkarıldı', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> moveExerciseToDay(PlannedExercise exercise, String targetDay) async {
    if (targetDay == selectedDayKey.value) return;
    isLoading.value = true;
    try {
      final currentPlanName = planNames[selectedDayKey.value];
      final updatedToday = todayPlan.where((p) => p.exerciseId != exercise.exerciseId).toList();
      final targetPlan = await repository.getPlanForDay(userId, targetDay);
      final targetExercises = [
        ...targetPlan.exercises.where((p) => p.exerciseId != exercise.exerciseId),
        exercise,
      ];

      await repository.updatePlanForDay(
        userId: userId,
        dayKey: selectedDayKey.value,
        exercises: updatedToday,
        planName: currentPlanName,
      );
      await repository.updatePlanForDay(
        userId: userId,
        dayKey: targetDay,
        exercises: targetExercises,
        planName: targetPlan.name,
      );

      todayPlan.assignAll(updatedToday);
      planNames[targetDay] = targetPlan.name;
      logsByExerciseId.remove(exercise.exerciseId);
      nextWeights.remove(exercise.exerciseId);
      savedExercises.remove(exercise.exerciseId);
      savingExercises.remove(exercise.exerciseId);
      nextWeights.refresh();
      logsByExerciseId.refresh();
      savedExercises.refresh();
      savingExercises.refresh();
      final targetLabel =
          ExerciseRepository.weekDayLabels[targetDay] ?? targetDay.toUpperCase();
      Get.snackbar('Başarılı', 'Egzersiz $targetLabel gününe taşındı',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSetLog({
    required String exerciseId,
    required int setNo,
    required int reps,
    double? weight,
    int? seconds,
  }) {
    final logs = [...(logsByExerciseId[exerciseId] ?? <SetLog>[])];
    final newLog = SetLog(setNo: setNo, reps: reps, weight: weight, seconds: seconds);
    final index = logs.indexWhere((l) => l.setNo == setNo);
    if (index >= 0) {
      logs[index] = newLog;
    } else {
      logs.add(newLog);
    }
    logs.sort((a, b) => a.setNo.compareTo(b.setNo));
    logsByExerciseId[exerciseId] = logs;
    logsByExerciseId.refresh();
    savedExercises[exerciseId] = false;
    savedExercises.refresh();
  }

  void updateNextWeight(String exerciseId, double? value) {
    nextWeights[exerciseId] = value;
    nextWeights.refresh();
    savedExercises[exerciseId] = false;
    savedExercises.refresh();
  }

  Future<void> saveExercise(String exerciseId) async {
    final plan = todayPlan.firstWhereOrNull((p) => p.exerciseId == exerciseId);
    if (plan == null) {
      Get.snackbar('Hata', 'Egzersiz bulunamadı', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    savingExercises[exerciseId] = true;
    savingExercises.refresh();

    final logs = logsByExerciseId[exerciseId] ?? <SetLog>[];
    final next = nextWeights[exerciseId];

    try {
      await repository.saveWorkoutSession(
        userId: userId,
        planId: selectedDayKey.value,
        date: DateTime.now(),
        planned: [plan],
        logsByExerciseId: {exerciseId: logs},
        nextWeights: {exerciseId: next},
        planForCache: todayPlan.toList(),
      );
      savedExercises[exerciseId] = true;
      savedExercises.refresh();
      Get.snackbar('Başarılı', '${plan.name} kaydedildi', snackPosition: SnackPosition.BOTTOM);
    } catch (e, stack) {
      log(
        'saveExercise failed (type=${e.runtimeType}, innerType=${_innerError(e)?.runtimeType}, inner=${_innerError(e)}, innerStack=${_innerStack(e)}, native=${_describeNativeError(e)}, planned=${plan.toMap()}, logs=${logs.map((l) => l.toMap()).toList()}, next=$next)',
        error: e,
        stackTrace: stack,
      );
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      savingExercises[exerciseId] = false;
      savingExercises.refresh();
    }
  }

  Future<void> saveTodayWorkout() async {
    isLoading.value = true;
    try {
      final planId = selectedDayKey.value;
      await repository.saveWorkoutSession(
        userId: userId,
        planId: planId,
        date: DateTime.now(),
        planned: todayPlan,
        logsByExerciseId: Map<String, List<SetLog>>.from(logsByExerciseId),
        nextWeights: Map<String, double?>.from(nextWeights),
      );
      Get.snackbar('Başarılı', 'Antrenman kaydedildi', snackPosition: SnackPosition.BOTTOM);
      await loadPlanForSelectedDay();
    } catch (e, stack) {
      log(
        'saveTodayWorkout failed (type=${e.runtimeType}, innerType=${_innerError(e)?.runtimeType}, inner=${_innerError(e)}, innerStack=${_innerStack(e)}, native=${_describeNativeError(e)}, planned=${todayPlan.map((p) => p.toMap()).toList()}, logs=${logsByExerciseId.map((k, v) => MapEntry(k, v.map((l) => l.toMap()).toList()))}, next=$nextWeights)',
        error: e,
        stackTrace: stack,
      );
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Object? _innerError(Object e) {
    try {
      return (e as dynamic).error;
    } catch (_) {
      return null;
    }
  }

  Object? _innerStack(Object e) {
    try {
      return (e as dynamic).stack;
    } catch (_) {
      return null;
    }
  }

  String _describeNativeError(Object e) {
    if (e.runtimeType.toString() != 'NativeError') return '';
    final buffer = StringBuffer();
    try {
      final inner = (e as dynamic).error;
      buffer.write('error=$inner');
      try {
        buffer.write(', code=${(inner as dynamic).code}');
      } catch (_) {}
      try {
        buffer.write(', message=${(inner as dynamic).message}');
      } catch (_) {}
      try {
        buffer.write(', name=${(inner as dynamic).name}');
      } catch (_) {}
      try {
        buffer.write(', stack=${(inner as dynamic).stack}');
      } catch (_) {}
    } catch (_) {}
    return buffer.toString();
  }
}
