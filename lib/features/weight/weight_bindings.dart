import 'package:get/get.dart';

import 'controllers/weight_controller.dart';
import 'data/weight_repository.dart';

class WeightBindings extends Bindings {
   WeightBindings({required this.userId});

  final String userId;

  @override
  void dependencies() {
    Get.lazyPut<WeightRepository>(() => WeightRepository());
    Get.put<WeightController>(
      WeightController(repository: Get.find<WeightRepository>(), userId: userId),
      permanent: true,
    );
  }
}
