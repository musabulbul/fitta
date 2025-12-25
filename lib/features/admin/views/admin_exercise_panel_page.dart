import 'package:flutter/material.dart';

import '../exercise_excel_service.dart';
import 'package:fitta/core/widgets/fitta_app_bar.dart';
import 'package:fitta/core/widgets/fitta_card.dart';

class AdminExercisePanelPage extends StatelessWidget {
  const AdminExercisePanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ExerciseExcelService();
    return Scaffold(
      appBar: const FittaAppBar(title: 'Egzersiz Yönetimi (Excel)'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FittaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Excel işlemleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: service.downloadExerciseTemplate,
                  child: const Text('Egzersiz Şablonu İndir (XLSX)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: service.importExercisesFromExcel,
                  child: const Text('Excel’den Egzersiz Yükle (XLSX)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: service.exportExercisesToExcel,
                  child: const Text('Mevcut Egzersiz Listesini XLSX Olarak İndir'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
