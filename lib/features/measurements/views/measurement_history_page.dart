import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/measurement_controller.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_entry.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class MeasurementHistoryPage extends StatefulWidget {
  const MeasurementHistoryPage({super.key});

  @override
  State<MeasurementHistoryPage> createState() => _MeasurementHistoryPageState();
}

class _MeasurementHistoryPageState extends State<MeasurementHistoryPage> {
  late final MeasurementController controller;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
  }

  MeasurementController _provideController() {
    if (Get.isRegistered<MeasurementController>()) return Get.find<MeasurementController>();
    const demoUserId = 'demoUser';
    return Get.put(MeasurementController(
      repository: MeasurementRepository(),
      userId: demoUserId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const FittaAppBar(title: 'Ölçü Geçmişi'),
      body: Obx(() {
        final list = controller.entries.toList();
        if (list.isEmpty) {
          return const Center(child: Text('Henüz kayıt yok.'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FittaCard(
              child: Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  'Bel çevresi grafiği burada gösterilecek',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            AppSpacing.vMd,
            ...list.map((e) => _EntryTile(entry: e)),
          ],
        );
      }),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final MeasurementEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(entry.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FittaCard(
        child: ListTile(
          title: Text(date),
          subtitle: Text(
            'Bel: ${entry.waist?.toStringAsFixed(1) ?? '--'} • Göğüs: ${entry.chest?.toStringAsFixed(1) ?? '--'} • Biceps: ${entry.biceps?.toStringAsFixed(1) ?? '--'}',
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
