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
    final entry = MeasurementEntry(
      id: '',
      date: DateTime.now(),
      chest: _parseOrNull(chest.value),
      waist: _parseOrNull(waist.value),
      hip: _parseOrNull(hip.value),
      biceps: _parseOrNull(biceps.value),
      thigh: _parseOrNull(thigh.value),
      calf: _parseOrNull(calf.value),
    );

    isLoading.value = true;
    try {
      await repository.addEntry(userId, entry);
      lastEntry.value = entry;
      _clearInputs();
      Get.snackbar('Kaydedildi', 'Ölçüler kaydedildi', snackPosition: SnackPosition.BOTTOM);
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

  void _clearInputs() {
    chest.value = '';
    waist.value = '';
    hip.value = '';
    biceps.value = '';
    thigh.value = '';
    calf.value = '';
  }
}
