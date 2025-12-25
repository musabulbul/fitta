import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/weight_controller.dart';
import '../data/weight_repository.dart';
import '../models/weight_entry.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class WeightChartPage extends StatefulWidget {
  const WeightChartPage({super.key});

  @override
  State<WeightChartPage> createState() => _WeightChartPageState();
}

class _WeightChartPageState extends State<WeightChartPage> {
  late final WeightController controller;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
  }

  WeightController _provideController() {
    if (Get.isRegistered<WeightController>()) return Get.find<WeightController>();
    const demoUser = 'demoUser';
    return Get.put(WeightController(repository: WeightRepository(), userId: demoUser));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FittaAppBar(title: 'Kilo & Yağ Grafiği'),
      body: Obx(() {
        final data = controller.entries.toList();
        if (data.isEmpty) {
          return const Center(child: Text('Veri bulunamadı.'));
        }
        final minWeight =
            data.map((e) => e.weight).reduce((a, b) => a < b ? a : b).toStringAsFixed(1);
        final maxWeight =
            data.map((e) => e.weight).reduce((a, b) => a > b ? a : b).toStringAsFixed(1);
        final avgWeight = (data.map((e) => e.weight).reduce((a, b) => a + b) / data.length)
            .toStringAsFixed(1);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FittaCard(
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _WeightChartPainter(entries: data),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            AppSpacing.vSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Min: $minWeight kg'),
                Text('Max: $maxWeight kg'),
                Text('Ort: $avgWeight kg'),
              ],
            ),
            AppSpacing.vMd,
            Text('Kayıtlar', style: Theme.of(context).textTheme.headlineSmall),
            AppSpacing.vSm,
            ...data.map((e) => _EntryTile(entry: e)),
          ],
        );
      }),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    final date = _format(entry.date);
    final fat = entry.bodyFatPercent != null ? '${entry.bodyFatPercent!.toStringAsFixed(1)}%' : '--';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FittaCard(
        child: ListTile(
          title: Text('$date • ${entry.weight.toStringAsFixed(1)} kg'),
          subtitle: Text('Yağ %: $fat'),
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.entries});

  final List<WeightEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final paintLine = Paint()
      ..color = const Color(0xFFFF6B00)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    final sorted = entries.toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // chronological
    final weights = sorted.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(1, double.infinity);

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    final stepX = size.width / (sorted.length - 1);
    final path = Path();
    for (int i = 0; i < sorted.length; i++) {
      final x = stepX * i;
      final y = size.height -
          ((sorted[i].weight - minW) / range) * size.height; // higher weight -> higher point
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
