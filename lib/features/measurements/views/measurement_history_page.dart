import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/measurement_controller.dart';
import '../data/measurement_repository.dart';
import '../models/measurement_entry.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class MeasurementHistoryPage extends StatefulWidget {
  const MeasurementHistoryPage({
    super.key,
    this.userId,
    this.clientName,
  });

  final String? userId;
  final String? clientName;

  @override
  State<MeasurementHistoryPage> createState() => _MeasurementHistoryPageState();
}

class _MeasurementHistoryPageState extends State<MeasurementHistoryPage> {
  late final MeasurementController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
  }

  MeasurementController _provideController() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    final tag = _controllerTag();
    if (tag != null) {
      if (Get.isRegistered<MeasurementController>(tag: tag)) {
        _ownsController = false;
        return Get.find<MeasurementController>(tag: tag);
      }
      _ownsController = true;
      return Get.put(
        MeasurementController(
          repository: MeasurementRepository(),
          userId: userId,
        ),
        tag: tag,
      );
    }
    if (Get.isRegistered<MeasurementController>()) {
      _ownsController = false;
      return Get.find<MeasurementController>();
    }
    _ownsController = true;
    return Get.put(MeasurementController(
      repository: MeasurementRepository(),
      userId: userId,
    ));
  }

  @override
  void dispose() {
    if (_ownsController) {
      final tag = _controllerTag();
      if (tag != null && Get.isRegistered<MeasurementController>(tag: tag)) {
        Get.delete<MeasurementController>(tag: tag);
      } else if (tag == null && Get.isRegistered<MeasurementController>()) {
        Get.delete<MeasurementController>();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.clientName?.isNotEmpty == true
        ? '${widget.clientName} • Ölçü Geçmişi'
        : 'Ölçü Geçmişi';
    return Scaffold(
      appBar: FittaAppBar(title: title),
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

  String? _controllerTag() {
    if (widget.userId == null) return null;
    return 'measurement-${widget.userId}';
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
