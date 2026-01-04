import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'measurement_history_page.dart';
import '../controllers/measurement_controller.dart';
import '../data/measurement_repository.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';

class MeasurementsPage extends StatefulWidget {
  const MeasurementsPage({
    super.key,
    this.userId,
    this.clientName,
    this.readOnly = false,
    this.onBackToProfile,
  });

  final String? userId;
  final String? clientName;
  final bool readOnly;
  final VoidCallback? onBackToProfile;

  @override
  State<MeasurementsPage> createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends State<MeasurementsPage> {
  late final MeasurementController controller;
  final chestCtrl = TextEditingController();
  final waistCtrl = TextEditingController();
  final hipCtrl = TextEditingController();
  final bicepsCtrl = TextEditingController();
  final thighCtrl = TextEditingController();
  final calfCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = _provideController();
    _bindInputs();
  }

  MeasurementController _provideController() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    final tag = _controllerTag();
    if (tag != null) {
      if (Get.isRegistered<MeasurementController>(tag: tag)) {
        return Get.find<MeasurementController>(tag: tag);
      }
      return Get.put(
        MeasurementController(
          repository: MeasurementRepository(),
          userId: userId,
        ),
        tag: tag,
      );
    }
    if (Get.isRegistered<MeasurementController>()) {
      return Get.find<MeasurementController>();
    }
    return Get.put(MeasurementController(
      repository: MeasurementRepository(),
      userId: userId,
    ));
  }

  void _bindInputs() {
    ever<String>(controller.chest, (v) {
      if (chestCtrl.text != v) chestCtrl.text = v;
    });
    ever<String>(controller.waist, (v) {
      if (waistCtrl.text != v) waistCtrl.text = v;
    });
    ever<String>(controller.hip, (v) {
      if (hipCtrl.text != v) hipCtrl.text = v;
    });
    ever<String>(controller.biceps, (v) {
      if (bicepsCtrl.text != v) bicepsCtrl.text = v;
    });
    ever<String>(controller.thigh, (v) {
      if (thighCtrl.text != v) thighCtrl.text = v;
    });
    ever<String>(controller.calf, (v) {
      if (calfCtrl.text != v) calfCtrl.text = v;
    });
  }

  @override
  void dispose() {
    final tag = _controllerTag();
    if (tag != null && Get.isRegistered<MeasurementController>(tag: tag)) {
      Get.delete<MeasurementController>(tag: tag);
    }
    chestCtrl.dispose();
    waistCtrl.dispose();
    hipCtrl.dispose();
    bicepsCtrl.dispose();
    thighCtrl.dispose();
    calfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.clientName?.isNotEmpty == true
        ? '${widget.clientName} • Ölçü Takip'
        : 'Ölçü Takip';
    final actions = <Widget>[];
    if (widget.onBackToProfile != null) {
      actions.add(
        TextButton(
          onPressed: widget.onBackToProfile,
          child: const Text('Profilim'),
        ),
      );
    }
    return Scaffold(
      appBar: FittaAppBar(
        title: title,
        actions: actions.isEmpty ? null : actions,
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FittaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ölçüler', style: theme.textTheme.headlineSmall),
                  AppSpacing.vSm,
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Göğüs (cm)',
                          chestCtrl,
                          widget.readOnly ? null : (v) => controller.chest.value = v,
                        ),
                      ),
                      AppSpacing.hSm,
                      Expanded(
                        child: _field(
                          'Bel (cm)',
                          waistCtrl,
                          widget.readOnly ? null : (v) => controller.waist.value = v,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSm,
                  Row(
                    children: [
                      Expanded(
                          child: _field(
                        'Kalça (cm)',
                        hipCtrl,
                        widget.readOnly ? null : (v) => controller.hip.value = v,
                      )),
                      AppSpacing.hSm,
                      Expanded(
                        child: _field(
                          'Biceps (cm)',
                          bicepsCtrl,
                          widget.readOnly ? null : (v) => controller.biceps.value = v,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vSm,
                  Row(
                    children: [
                      Expanded(
                          child: _field(
                        'Uyluk (cm)',
                        thighCtrl,
                        widget.readOnly ? null : (v) => controller.thigh.value = v,
                      )),
                      AppSpacing.hSm,
                      Expanded(
                          child: _field(
                        'Baldır (cm)',
                        calfCtrl,
                        widget.readOnly ? null : (v) => controller.calf.value = v,
                      )),
                    ],
                  ),
                  AppSpacing.vMd,
                  PrimaryButton(
                    label:
                        controller.isLoading.value ? 'Kaydediliyor...' : 'Kaydet',
                    onPressed:
                        widget.readOnly || controller.isLoading.value
                            ? null
                            : controller.saveTodayEntry,
                  ),
                  TextButton(
                    onPressed: () => Get.to(
                      () => MeasurementHistoryPage(
                        userId: widget.userId,
                        clientName: widget.clientName,
                      ),
                    ),
                    child: const Text('Geçmişi Gör'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    ValueChanged<String>? onChanged,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      enabled: onChanged != null,
      onChanged: onChanged,
    );
  }

  String? _controllerTag() {
    if (widget.userId == null) return null;
    return 'measurement-${widget.userId}';
  }
}
