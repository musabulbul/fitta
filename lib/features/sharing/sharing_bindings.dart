import 'package:get/get.dart';

import 'controllers/sharing_controller.dart';
import 'data/sharing_repository.dart';

class SharingBindings extends Bindings {
  SharingBindings({
    required this.ownerUserId,
    required this.currentUserEmail,
    required this.ownerDisplayName,
    required this.ownerPhotoUrl,
  });

  final String ownerUserId;
  final String currentUserEmail;
  final String ownerDisplayName;
  final String ownerPhotoUrl;

  @override
  void dependencies() {
    Get.lazyPut<SharingRepository>(() => SharingRepository());
    Get.put<SharingController>(
      SharingController(
        repository: Get.find<SharingRepository>(),
        ownerUserId: ownerUserId,
        currentUserEmail: currentUserEmail,
        ownerDisplayName: ownerDisplayName,
        ownerPhotoUrl: ownerPhotoUrl,
      ),
      permanent: true,
    );
  }
}
