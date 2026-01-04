import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'weight_chart_page.dart';
import '../controllers/weight_controller.dart';
import '../data/weight_repository.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({
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
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  late final WeightController controller;
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final waistCtrl = TextEditingController();
  final hipCtrl = TextEditingController();
  final neckCtrl = TextEditingController();

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
    _bindInputs();
  }

  WeightController _provideController() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    final tag = _controllerTag();
    if (tag != null) {
      if (Get.isRegistered<WeightController>(tag: tag)) {
        return Get.find<WeightController>(tag: tag);
      }
      return Get.put(
        WeightController(repository: WeightRepository(), userId: userId),
        tag: tag,
      );
    }
    if (Get.isRegistered<WeightController>()) {
      return Get.find<WeightController>();
    }
    return Get.put(WeightController(repository: WeightRepository(), userId: userId));
  }

  void _bindInputs() {
    ever<String>(controller.weight, (v) {
      if (weightCtrl.text != v) weightCtrl.text = v;
    });
    ever<String>(controller.height, (v) {
      if (heightCtrl.text != v) heightCtrl.text = v;
    });
    ever<String>(controller.waist, (v) {
      if (waistCtrl.text != v) waistCtrl.text = v;
    });
    ever<String>(controller.hip, (v) {
      if (hipCtrl.text != v) hipCtrl.text = v;
    });
    ever<String>(controller.neck, (v) {
      if (neckCtrl.text != v) neckCtrl.text = v;
    });
  }

  @override
  void dispose() {
    final tag = _controllerTag();
    if (tag != null && Get.isRegistered<WeightController>(tag: tag)) {
      Get.delete<WeightController>(tag: tag);
    }
    weightCtrl.dispose();
    heightCtrl.dispose();
    waistCtrl.dispose();
    hipCtrl.dispose();
    neckCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.clientName?.isNotEmpty == true
        ? '${widget.clientName} • Kilo & Yağ Oranı'
        : 'Kilo & Yağ Oranı';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FittaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugünkü Kilo', style: theme.textTheme.headlineSmall),
                AppSpacing.vSm,
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  style: theme.textTheme.headlineLarge,
                  enabled: !widget.readOnly,
                  decoration: const InputDecoration(
                    suffixText: 'kg',
                    hintText: 'Örn: 80.5',
                  ),
                  onChanged: widget.readOnly ? null : (v) => controller.weight.value = v,
                ),
                AppSpacing.vSm,
                Text(
                  'Diğer değerler son kayıttan doldurulur.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppSpacing.vSm,
          FittaCard(
            child: ExpansionTile(
              title: const Text('Diğer Ölçüler (opsiyonel)'),
              initiallyExpanded: expanded,
              onExpansionChanged: (v) => setState(() => expanded = v),
              childrenPadding: const EdgeInsets.only(bottom: 12, left: 16, right: 16, top: 12),
              children: [
                _InputRow(
                  label: 'Boy (cm)',
                  controller: heightCtrl,
                  onChanged: (v) => controller.height.value = v,
                  enabled: !widget.readOnly,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Bel (cm)',
                  controller: waistCtrl,
                  onChanged: (v) => controller.waist.value = v,
                  enabled: !widget.readOnly,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Kalça (Sadece Kadınlar)',
                  controller: hipCtrl,
                  onChanged: (v) => controller.hip.value = v,
                  enabled: !widget.readOnly,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Boyun (cm)',
                  controller: neckCtrl,
                  onChanged: (v) => controller.neck.value = v,
                  enabled: !widget.readOnly,
                ),
                AppSpacing.vSm,
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'male',
                          groupValue: controller.gender.value,
                          title: const Text('Erkek'),
                          onChanged: widget.readOnly
                              ? null
                              : (v) => controller.gender.value = v ?? 'male',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'female',
                          groupValue: controller.gender.value,
                          title: const Text('Kadın'),
                          onChanged: widget.readOnly
                              ? null
                              : (v) => controller.gender.value = v ?? 'female',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vMd,
          Obx(
            () => PrimaryButton(
              label: controller.isLoading.value ? 'Kaydediliyor...' : 'Kaydet',
              icon: const Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
              onPressed: widget.readOnly || controller.isLoading.value
                  ? null
                  : controller.saveTodayEntry,
            ),
          ),
          TextButton(
            onPressed: () => Get.to(
              () => WeightChartPage(
                userId: widget.userId,
                clientName: widget.clientName,
                readOnly: widget.readOnly,
                onBackToProfile: widget.onBackToProfile,
              ),
            ),
            child: const Text('Grafikleri Gör'),
          ),
        ],
      ),
    );
  }

  String? _controllerTag() {
    if (widget.userId == null) return null;
    return 'weight-${widget.userId}';
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
      onChanged: enabled ? onChanged : null,
    );
  }
}
