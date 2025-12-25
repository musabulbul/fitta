import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fitta/features/measurements/controllers/measurement_controller.dart';
import 'package:fitta/features/measurements/data/measurement_repository.dart';
import 'package:fitta/features/measurements/models/measurement_entry.dart';

// Manual Mock
class MockMeasurementRepository implements MeasurementRepository {
  final List<MeasurementEntry> _store = [];

  @override
  final dynamic firestore = null;

  @override
  Future<void> addEntry(String userId, MeasurementEntry entry) async {
    final index = _store.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _store[index] = entry;
    } else {
      final newEntry = entry.copyWith(id: entry.id.isEmpty ? 'new_id_${_store.length}' : entry.id);
      _store.add(newEntry);
    }
  }

  @override
  Future<MeasurementEntry?> getLastEntry(String userId) async {
    if (_store.isEmpty) return null;
    _store.sort((a, b) => b.date.compareTo(a.date));
    return _store.first;
  }

  @override
  Stream<List<MeasurementEntry>> watchEntries(String userId) {
    return Stream.value(_store);
  }

  Future<MeasurementEntry?> getEntryByDate(String userId, DateTime date) async {
    try {
      return _store.firstWhere((e) {
        return e.date.year == date.year &&
               e.date.month == date.month &&
               e.date.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }
}

void main() {
  late MeasurementController controller;
  late MockMeasurementRepository mockRepo;

  setUp(() {
    mockRepo = MockMeasurementRepository();
    controller = MeasurementController(repository: mockRepo, userId: 'test_user');
  });

  test('Should not save if all inputs are empty', () async {
    // Current impl allows saving empty! We want to prevent this.
    await controller.saveTodayEntry();
    expect((await mockRepo.getLastEntry('test_user')), isNull, reason: "Should not save empty entry");
  });

  test('Should validate negative inputs', () async {
    controller.waist.value = '-10';
    await controller.saveTodayEntry();
    expect((await mockRepo.getLastEntry('test_user')), isNull, reason: "Should not save negative values");
  });
}
