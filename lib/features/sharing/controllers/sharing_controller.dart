import 'package:get/get.dart';

import '../data/sharing_repository.dart';
import '../models/client_link.dart';
import '../models/share_permission.dart';

class SharingController extends GetxController {
  SharingController({
    required this.repository,
    required this.ownerUserId,
    required this.currentUserEmail,
  });

  final SharingRepository repository;
  final String ownerUserId;
  final String currentUserEmail;

  final isLoading = false.obs;
  final emailInput = ''.obs;
  final selectedRole = 'trainer'.obs;

  final sharedWith = <SharePermission>[].obs;
  final clients = <ClientLink>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenSharedWith();
    _listenClients();
  }

  void _listenSharedWith() {
    sharedWith.bindStream(repository.watchSharedWith(ownerUserId));
  }

  void _listenClients() {
    clients.bindStream(repository.watchClients(ownerUserId));
  }

  Future<void> addShare() async {
    final email = emailInput.value.trim();
    if (email.isEmpty) {
      Get.snackbar('Eksik bilgi', 'Lütfen paylaşmak için e-posta girin',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final targetUserId = await repository.findUserIdByEmail(email);
      if (targetUserId == null) {
        Get.snackbar('Bulunamadı', 'Bu e-posta ile kullanıcı bulunamadı',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (targetUserId == ownerUserId) {
        Get.snackbar('Geçersiz', 'Kendi hesabınıza erişim eklemeye gerek yok',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      await repository.addSharePermission(
        ownerUserId: ownerUserId,
        targetUserId: targetUserId,
        role: selectedRole.value,
      );
      Get.snackbar('Paylaşıldı', 'Yetki eklendi', snackPosition: SnackPosition.BOTTOM);
      emailInput.value = '';
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeShare(String targetUserId) async {
    isLoading.value = true;
    try {
      await repository.removeSharePermission(
        ownerUserId: ownerUserId,
        targetUserId: targetUserId,
      );
      Get.snackbar('Kaldırıldı', 'Yetki kaldırıldı', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
