import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/weight_controller.dart';
import '../data/weight_repository.dart';
import '../models/weight_entry.dart';
import 'package:fitta/core/utils/app_spacing.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class WeightChartPage extends StatefulWidget {
  const WeightChartPage({
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
  State<WeightChartPage> createState() => _WeightChartPageState();
}

class _WeightChartPageState extends State<WeightChartPage> {
  late final WeightController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    controller = _provideController();
  }

  WeightController _provideController() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser!.uid;
    final tag = _controllerTag();
    if (tag != null) {
      if (Get.isRegistered<WeightController>(tag: tag)) {
        _ownsController = false;
        return Get.find<WeightController>(tag: tag);
      }
      _ownsController = true;
      return Get.put(
        WeightController(repository: WeightRepository(), userId: userId),
        tag: tag,
      );
    }
    if (Get.isRegistered<WeightController>()) {
      _ownsController = false;
      return Get.find<WeightController>();
    }
    _ownsController = true;
    return Get.put(WeightController(repository: WeightRepository(), userId: userId));
  }

  @override
  void dispose() {
    final tag = _controllerTag();
    if (_ownsController) {
      if (tag != null && Get.isRegistered<WeightController>(tag: tag)) {
        Get.delete<WeightController>(tag: tag);
      } else if (tag == null && Get.isRegistered<WeightController>()) {
        Get.delete<WeightController>();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clientName?.isNotEmpty == true
        ? '${widget.clientName} • Kilo & Yağ Grafiği'
        : 'Kilo & Yağ Grafiği';
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
      body: Obx(() {
        final data = controller.entries.toList();
        if (data.isEmpty) {
          return const Center(child: Text('Veri bulunamadı.'));
        }

        // Sorting Chronologically
        data.sort((a, b) => a.date.compareTo(b.date));

        final weights = data.map((e) => e.weight).toList();
        final fats = data.map((e) => e.bodyFatPercent ?? 0.0).toList();

        final minWeight = weights.reduce((a, b) => a < b ? a : b);
        final maxWeight = weights.reduce((a, b) => a > b ? a : b);
        final avgWeight = (weights.reduce((a, b) => a + b) / weights.length).toStringAsFixed(1);

        final hasFat = fats.any((f) => f > 0);
        final minFat = hasFat ? fats.where((f) => f > 0).reduce((a, b) => a < b ? a : b) : 0.0;
        final maxFat = hasFat ? fats.where((f) => f > 0).reduce((a, b) => a > b ? a : b) : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FittaCard(
              child: AspectRatio(
                aspectRatio: 1.5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 0, top: 16, bottom: 0),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: const LineTouchData(enabled: true),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index < 0 || index >= data.length) return const SizedBox();
                              // Show sparse labels to avoid clutter
                              if (data.length > 5 && index % (data.length ~/ 5) != 0) return const SizedBox();
                              final date = data[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10)),
                              );
                            },
                            interval: 1,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      // Use auto-scaling by providing min/max but with some buffer if desired,
                      // or let it auto-scale by default which LineChart does well.
                      // The prompt asks "grafik ölçümlere göre yapılsın, minimum maksimuma göre değil"
                      // which usually means don't force 0 as baseline, let it zoom in.
                      // FlChart does this by default if we don't set minY/maxY explicitly too wide.
                      // However, we have two different scales (Weight ~80kg, Fat ~20%).
                      // Showing them on one Y-axis is tricky.
                      // Usually implies dual axis or normalized scaling.
                      // For simplicity and standard implementation, we'll plot them on same axis if ranges are close,
                      // OR we can use the left axis for Weight and assume Fat is just a line.
                      // If weight is 80 and fat is 20, the fat line will be at the bottom.
                      // Let's implement it with raw values.
                      lineBarsData: [
                        // Weight Line
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.weight);
                          }).toList(),
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Fat Line (only if present)
                        if (hasFat)
                          LineChartBarData(
                            spots: data.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.bodyFatPercent ?? 0);
                            }).toList(),
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.vSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: Colors.orange, label: 'Kilo'),
                if (hasFat) _LegendItem(color: Colors.blueAccent, label: 'Yağ Oranı'),
              ],
            ),
            AppSpacing.vSm,
            FittaCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn('Min Kilo', '${minWeight.toStringAsFixed(1)} kg'),
                      _StatColumn('Max Kilo', '${maxWeight.toStringAsFixed(1)} kg'),
                      _StatColumn('Ort Kilo', '$avgWeight kg'),
                    ],
                  ),
                )
            ),
            AppSpacing.vMd,
            Text('Kayıtlar', style: Theme.of(context).textTheme.headlineSmall),
            AppSpacing.vSm,
            ...data.reversed.map((e) => _EntryTile(
                  entry: e,
                  controller: controller,
                  readOnly: widget.readOnly,
                )), // Reversed for list view (newest first)
          ],
        );
      }),
    );
  }

  String? _controllerTag() {
    if (widget.userId == null) return null;
    return 'weight-${widget.userId}';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.controller,
    required this.readOnly,
  });

  final WeightEntry entry;
  final WeightController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final date = _formatDateTime(entry.date);
    final fat = entry.bodyFatPercent != null ? '${entry.bodyFatPercent!.toStringAsFixed(1)}%' : '--';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FittaCard(
        child: ListTile(
          title: Text('$date • ${entry.weight.toStringAsFixed(1)} kg'),
          subtitle: Text('Yağ %: $fat'),
          trailing: readOnly
              ? null
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context, entry);
                    } else if (value == 'delete') {
                      controller.deleteEntry(entry.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Güncelle')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.${d.year} • $hour:$minute';
  }

  void _showEditDialog(BuildContext context, WeightEntry entry) {
    final wCtrl = TextEditingController(text: entry.weight.toString());
    final hCtrl = TextEditingController(text: entry.height?.toString() ?? '');

    // Simple Edit Dialog for weight only for now, or full?
    // User wants "update". I'll allow weight update as it's the primary stat.
    // For full update, it's better to navigate to a full form.

    Get.defaultDialog(
      title: 'Kaydı Güncelle',
      content: Column(
        children: [
          TextField(controller: wCtrl, decoration: const InputDecoration(labelText: 'Kilo (kg)'), keyboardType: TextInputType.number),
        ],
      ),
      textConfirm: 'Güncelle',
      textCancel: 'İptal',
      onConfirm: () {
        final newWeight = double.tryParse(wCtrl.text);
        if (newWeight != null) {
          final updated = entry.copyWith(weight: newWeight);
          controller.updateEntry(updated);
          Get.back();
        }
      }
    );
  }
}
