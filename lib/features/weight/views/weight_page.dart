import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'weight_chart_page.dart';
import '../controllers/weight_controller.dart';
import '../data/weight_repository.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';
import 'package:fitta/core/widgets/primary_button.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

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
    if (Get.isRegistered<WeightController>()) return Get.find<WeightController>();
    const demoUserId = 'demoUser';
    return Get.put(WeightController(repository: WeightRepository(), userId: demoUserId));
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
    return Scaffold(
      appBar: const FittaAppBar(title: 'Kilo & Yağ Oranı'),
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
                  decoration: const InputDecoration(
                    suffixText: 'kg',
                    hintText: 'Örn: 80.5',
                  ),
                  onChanged: (v) => controller.weight.value = v,
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
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [
                _InputRow(
                  label: 'Boy (cm)',
                  controller: heightCtrl,
                  onChanged: (v) => controller.height.value = v,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Bel (cm)',
                  controller: waistCtrl,
                  onChanged: (v) => controller.waist.value = v,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Kalça (cm)',
                  controller: hipCtrl,
                  onChanged: (v) => controller.hip.value = v,
                ),
                AppSpacing.vSm,
                _InputRow(
                  label: 'Boyun (cm)',
                  controller: neckCtrl,
                  onChanged: (v) => controller.neck.value = v,
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
                          onChanged: (v) => controller.gender.value = v ?? 'male',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'female',
                          groupValue: controller.gender.value,
                          title: const Text('Kadın'),
                          onChanged: (v) => controller.gender.value = v ?? 'female',
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
              onPressed: controller.isLoading.value ? null : controller.saveTodayEntry,
            ),
          ),
          TextButton(
            onPressed: () => Get.to(() => const WeightChartPage()),
            child: const Text('Grafikleri Gör'),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}
