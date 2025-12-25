import 'excel_file_saver_stub.dart'
    if (dart.library.html) 'excel_file_saver_web.dart'
    if (dart.library.io) 'excel_file_saver_io.dart';

Future<void> saveExcelFile(String filename, List<int> bytes) {
  return saveExcelFileImpl(filename, bytes);
}
