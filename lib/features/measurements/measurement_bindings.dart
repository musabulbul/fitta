import 'package:get/get.dart';

import 'controllers/measurement_controller.dart';
import 'data/measurement_repository.dart';

class MeasurementBindings extends Bindings {
  MeasurementBindings({required this.userId});

  final String userId;

  @override
  void dependencies() {
    Get.lazyPut<MeasurementRepository>(() => MeasurementRepository());
    Get.put<MeasurementController>(
      MeasurementController(repository: Get.find<MeasurementRepository>(), userId: userId),
      permanent: true,
    );
  }
}
