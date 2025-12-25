import 'package:get/get.dart';

import 'controllers/sharing_controller.dart';
import 'data/sharing_repository.dart';

class SharingBindings extends Bindings {
   SharingBindings({required this.ownerUserId, required this.currentUserEmail});

  final String ownerUserId;
  final String currentUserEmail;

  @override
  void dependencies() {
    Get.lazyPut<SharingRepository>(() => SharingRepository());
    Get.put<SharingController>(
      SharingController(
        repository: Get.find<SharingRepository>(),
        ownerUserId: ownerUserId,
        currentUserEmail: currentUserEmail,
      ),
      permanent: true,
    );
  }
}
