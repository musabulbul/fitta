import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../exercises/models/exercise.dart';
import 'excel_file_saver.dart';

class ExerciseExcelService {
  ExerciseExcelService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _globalExercises =>
      firestore.collection('globalExercises');

  Future<void> downloadExerciseTemplate() async {
    try {
      final excel = Excel.createExcel();
      const sheetName = 'Exercises';
      final sheet = excel[sheetName];
      sheet.appendRow(
        [
          TextCellValue('id'),
          TextCellValue('name'),
          TextCellValue('category'),
          TextCellValue('type'),
          TextCellValue('keywords'),
          TextCellValue('imagePath'),
          TextCellValue('description'),
        ],
      );
      sheet.appendRow([
        TextCellValue('lat_pull_down'),
        TextCellValue('Lat Pull Down'),
        TextCellValue('Sırt'),
        TextCellValue('weight'),
        TextCellValue('lat;sırt;çekiş'),
        TextCellValue('exercises/lat_pull_down.png'),
        TextCellValue('Sırt kaslarını çalıştıran çekiş egzersizi.'),
      ]);
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Şablon oluşturulamadı');

      await saveExcelFile('fitta_exercise_template.xlsx', bytes);
      Get.snackbar('Şablon hazır', 'fitta_exercise_template.xlsx indirildi',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', 'Şablon indirme başarısız: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> exportExercisesToExcel() async {
    try {
      final snap = await _globalExercises.get();
      final excel = Excel.createExcel();
      const sheetName = 'Exercises';
      final sheet = excel[sheetName];
      sheet.appendRow(
        [
          TextCellValue('id'),
          TextCellValue('name'),
          TextCellValue('category'),
          TextCellValue('type'),
          TextCellValue('keywords'),
          TextCellValue('imagePath'),
          TextCellValue('description'),
        ],
      );

      for (final doc in snap.docs) {
        final data = doc.data();
        final exercise = Exercise.fromMap({'id': doc.id, ...data});
        sheet.appendRow([
          TextCellValue(exercise.id),
          TextCellValue(exercise.name),
          TextCellValue(exercise.category),
          TextCellValue(exercise.type),
          TextCellValue(exercise.keywords.join(';')),
          TextCellValue(exercise.imagePath ?? ''),
          TextCellValue(exercise.description ?? ''),
        ]);
      }
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel oluşturulamadı');

      await saveExcelFile('fitta_exercises_export.xlsx', bytes);
      Get.snackbar('Dışa aktarıldı', 'fitta_exercises_export.xlsx indirildi',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', 'Export başarısız: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> importExercisesFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception('Dosya içeriği okunamadı');
      final excel = Excel.decodeBytes(bytes);
      final sheet = _findExercisesSheet(excel);
      if (sheet == null) {
        throw Exception('Exercises sayfası bulunamadı');
      }

      final batch = firestore.batch();
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;
        final id = _cellString(row, 0);
        if (id.isEmpty) continue;
        final name = _cellString(row, 1);
        final category = _cellString(row, 2);
        final type = _cellString(row, 3).isEmpty ? 'weight' : _cellString(row, 3);
        final keywordsRaw = _cellString(row, 4);
        final imagePath = _cellString(row, 5);
        final description = _cellString(row, 6);

        final keywords = keywordsRaw
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final data = {
          'name': name,
          'category': category,
          'type': type,
          'keywords': keywords,
          'imagePath': imagePath.isEmpty ? null : imagePath,
          'description': description.isEmpty ? null : description,
        };

        final ref = _globalExercises.doc(id);
        batch.set(ref, data, SetOptions(merge: true));
      }
      await batch.commit();
      Get.snackbar('Başarılı', 'Egzersizler başarıyla güncellendi',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Hata', 'Import başarısız: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _cellString(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    return row[index]!.value.toString().trim();
  }

  Sheet? _findExercisesSheet(Excel excel) {
    const preferred = ['Exercises', 'Exercise', 'Egzersizler', 'Sheet1'];
    if (excel.sheets.isEmpty) return null;

    // Exact preferred name
    for (final name in preferred) {
      if (excel.sheets.containsKey(name)) return excel[name];
    }

    // Case-insensitive fallback
    final normalized = {
      for (final entry in excel.sheets.entries) entry.key.trim().toLowerCase(): entry.value
    };
    for (final name in preferred) {
      final hit = normalized[name.toLowerCase()];
      if (hit != null) return hit;
    }

    // Last resort: first sheet
    return excel.sheets.values.first;
  }
}
