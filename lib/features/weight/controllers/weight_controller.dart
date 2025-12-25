import 'package:get/get.dart';

import 'package:fitta/core/utils/body_fat_calculator.dart';
import '../data/weight_repository.dart';
import '../models/weight_entry.dart';

class WeightController extends GetxController {
  WeightController({
    required this.repository,
    required this.userId,
  });

  final WeightRepository repository;
  final String userId;

  final isLoading = false.obs;
  final lastEntry = Rxn<WeightEntry>();
  final entries = <WeightEntry>[].obs;

  final weight = ''.obs;
  final height = ''.obs;
  final waist = ''.obs;
  final hip = ''.obs;
  final neck = ''.obs;
  final gender = 'male'.obs;

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
        weight.value = last.weight.toStringAsFixed(1);
        height.value = last.height?.toStringAsFixed(1) ?? '';
        waist.value = last.waist?.toStringAsFixed(1) ?? '';
        hip.value = last.hip?.toStringAsFixed(1) ?? '';
        neck.value = last.neck?.toStringAsFixed(1) ?? '';
        gender.value = last.gender ?? gender.value;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _listenEntries() {
    entries.bindStream(repository.watchEntries(userId));
  }

  Future<void> saveTodayEntry() async {
    final parsedWeight = double.tryParse(weight.value);
    if (parsedWeight == null) {
      Get.snackbar('Eksik bilgi', 'Lütfen kilo değerini girin', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final parsedHeight = _parseOrFallback(height.value, lastEntry.value?.height);
    final parsedWaist = _parseOrFallback(waist.value, lastEntry.value?.waist);
    final parsedHip = _parseOrFallback(hip.value, lastEntry.value?.hip);
    final parsedNeck = _parseOrFallback(neck.value, lastEntry.value?.neck);
    final genderValue = (gender.value.isNotEmpty ? gender.value : lastEntry.value?.gender) ?? 'male';

    final bodyFat = (parsedHeight != null && parsedWaist != null && parsedNeck != null)
        ? calculateBodyFat(
            gender: genderValue,
            height: parsedHeight,
            waist: parsedWaist,
            hip: parsedHip,
            neck: parsedNeck,
          )
        : null;

    final entry = WeightEntry(
      id: '',
      date: DateTime.now(),
      weight: parsedWeight,
      height: parsedHeight,
      waist: parsedWaist,
      hip: parsedHip,
      neck: parsedNeck,
      gender: genderValue,
      bodyFatPercent: bodyFat,
    );

    isLoading.value = true;
    try {
      await repository.addEntry(userId, entry);
      lastEntry.value = entry;
      Get.snackbar('Kaydedildi', 'Güncel kilo ve ölçüler kaydedildi',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  double? _parseOrFallback(String value, double? fallback) {
    if (value.trim().isEmpty) return fallback;
    return double.tryParse(value);
  }
}
