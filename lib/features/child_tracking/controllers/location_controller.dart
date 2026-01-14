import 'package:get/get.dart';
import '../services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationController extends GetxController {
  final LocationService _locationService = LocationService();
  final isTracking = false.obs;

  @override
  void onClose() {
    _locationService.stopTracking();
    super.onClose();
  }

  Future<void> startTracking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _locationService.startTracking(user.uid);
      isTracking.value = true;
      Get.snackbar('Başarılı', 'Konum takibi başlatıldı');
    } catch (e) {
      Get.snackbar('Hata', 'Konum takibi başlatılamadı: $e');
      isTracking.value = false;
    }
  }

  Future<void> stopTracking() async {
    await _locationService.stopTracking();
    isTracking.value = false;
    Get.snackbar('Bilgi', 'Konum takibi durduruldu');
  }
}
