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
    if (parsedWeight == null || parsedWeight <= 0) {
      Get.snackbar('Geçersiz değer', 'Lütfen geçerli bir kilo değeri girin',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // We want to fallback to the values of the entry we are about to update (if it exists)
    // or the last known entry if it's a fresh update for today.
    // Since we fetch `existingEntry` later, we need to restructure this slightly or accept that `lastEntry`
    // is usually the correct fallback.
    // However, strictly speaking, `lastEntry` might be yesterday's data. If we edit today's entry,
    // we should use today's existing values as fallback for empty fields.

    // To do this correctly, we should fetch existingEntry *first*.
    isLoading.value = true;
    try {
      final today = DateTime.now();
      final existingEntry = await repository.getEntryByDate(userId, today);

      // Determine fallback source: existingEntry (today) -> lastEntry (previous)
      final fallbackEntry = existingEntry ?? lastEntry.value;

      final parsedHeight = _parseOrFallback(height.value, fallbackEntry?.height);
      final parsedWaist = _parseOrFallback(waist.value, fallbackEntry?.waist);
      final parsedHip = _parseOrFallback(hip.value, fallbackEntry?.hip);
      final parsedNeck = _parseOrFallback(neck.value, fallbackEntry?.neck);
      final genderValue =
          (gender.value.isNotEmpty ? gender.value : fallbackEntry?.gender) ??
              'male';

      if ((parsedHeight != null && parsedHeight <= 0) ||
          (parsedWaist != null && parsedWaist <= 0) ||
          (parsedHip != null && parsedHip <= 0) ||
          (parsedNeck != null && parsedNeck <= 0)) {
        Get.snackbar('Geçersiz değer', 'Ölçü değerleri 0\'dan büyük olmalıdır',
            snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        return;
      }

      final bodyFat =
          (parsedHeight != null && parsedWaist != null && parsedNeck != null)
              ? calculateBodyFat(
                  gender: genderValue,
                  height: parsedHeight,
                  waist: parsedWaist,
                  hip: parsedHip,
                  neck: parsedNeck,
                )
              : null;

      final entry = WeightEntry(
        id: existingEntry?.id ?? '',
        date: existingEntry?.date ?? today,
        weight: parsedWeight,
        height: parsedHeight,
        waist: parsedWaist,
        hip: parsedHip,
        neck: parsedNeck,
        gender: genderValue,
        bodyFatPercent: bodyFat,
      );

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

  Future<void> updateEntry(WeightEntry entry) async {
    isLoading.value = true;
    try {
      await repository.addEntry(userId, entry);
      Get.snackbar('Güncellendi', 'Kayıt güncellendi', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEntry(String id) async {
    isLoading.value = true;
    try {
      await repository.deleteEntry(userId, id);
      Get.snackbar('Silindi', 'Kayıt silindi', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
