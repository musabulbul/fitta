import 'package:get/get.dart';

import '../data/measurement_repository.dart';
import '../models/measurement_entry.dart';

class MeasurementController extends GetxController {
  MeasurementController({
    required this.repository,
    required this.userId,
  });

  final MeasurementRepository repository;
  final String userId;

  final isLoading = false.obs;
  final lastEntry = Rxn<MeasurementEntry>();
  final entries = <MeasurementEntry>[].obs;

  final chest = ''.obs;
  final waist = ''.obs;
  final hip = ''.obs;
  final biceps = ''.obs;
  final thigh = ''.obs;
  final calf = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLastEntry();
    _listenEntries();
  }

  Future<void> _loadLastEntry() async {
    try {
      isLoading.value = true;
      final last = await repository.getLastEntry(userId);
      lastEntry.value = last;
      if (last != null) {
        chest.value = last.chest?.toStringAsFixed(1) ?? '';
        waist.value = last.waist?.toStringAsFixed(1) ?? '';
        hip.value = last.hip?.toStringAsFixed(1) ?? '';
        biceps.value = last.biceps?.toStringAsFixed(1) ?? '';
        thigh.value = last.thigh?.toStringAsFixed(1) ?? '';
        calf.value = last.calf?.toStringAsFixed(1) ?? '';
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _listenEntries() {
    entries.bindStream(repository.watchEntries(userId));
  }

  Future<void> saveTodayEntry() async {
    final pChest = _parseOrNull(chest.value);
    final pWaist = _parseOrNull(waist.value);
    final pHip = _parseOrNull(hip.value);
    final pBiceps = _parseOrNull(biceps.value);
    final pThigh = _parseOrNull(thigh.value);
    final pCalf = _parseOrNull(calf.value);

    // Validate that at least one measurement is provided
    if (pChest == null &&
        pWaist == null &&
        pHip == null &&
        pBiceps == null &&
        pThigh == null &&
        pCalf == null) {
      Get.snackbar(
          'Eksik bilgi', 'Lütfen en az bir ölçü girin',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Validate non-negative values
    if ((pChest != null && pChest <= 0) ||
        (pWaist != null && pWaist <= 0) ||
        (pHip != null && pHip <= 0) ||
        (pBiceps != null && pBiceps <= 0) ||
        (pThigh != null && pThigh <= 0) ||
        (pCalf != null && pCalf <= 0)) {
      Get.snackbar(
          'Geçersiz değer', 'Ölçü değerleri 0\'dan büyük olmalıdır',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final today = DateTime.now();
      final existingEntry = await repository.getEntryByDate(userId, today);

      final entry = MeasurementEntry(
        id: existingEntry?.id ?? '',
        date: existingEntry?.date ?? today,
        chest: pChest ?? existingEntry?.chest,
        waist: pWaist ?? existingEntry?.waist,
        hip: pHip ?? existingEntry?.hip,
        biceps: pBiceps ?? existingEntry?.biceps,
        thigh: pThigh ?? existingEntry?.thigh,
        calf: pCalf ?? existingEntry?.calf,
      );

      await repository.addEntry(userId, entry);
      lastEntry.value = entry;
      // Removed _clearInputs() to allow user to see what they saved
      Get.snackbar('Kaydedildi', 'Ölçüler kaydedildi',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  double? _parseOrNull(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value);
  }

}
