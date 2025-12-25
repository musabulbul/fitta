import 'package:get/get.dart';
import '../data/package_repository.dart';
import '../models/workout_package.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PackageController extends GetxController {
  PackageController({
    required this.repository,
    String? userId,
  }) : userId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  final PackageRepository repository;
  final String userId;

  final packages = <WorkoutPackage>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    packages.bindStream(repository.watchPackages(userId));
  }

  Future<void> deletePackage(String packageId) async {
    try {
      await repository.deletePackage(userId: userId, packageId: packageId);
      Get.snackbar('Başarılı', 'Paket silindi');
    } catch (e) {
      Get.snackbar('Hata', 'Paket silinemedi: $e');
    }
  }
}
