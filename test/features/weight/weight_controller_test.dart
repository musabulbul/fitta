import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fitta/features/weight/controllers/weight_controller.dart';
import 'package:fitta/features/weight/data/weight_repository.dart';
import 'package:fitta/features/weight/models/weight_entry.dart';

// Manual Mock
class MockWeightRepository implements WeightRepository {
  final List<WeightEntry> _store = [];

  @override
  // ignore: overridden_fields
  final dynamic firestore = null;

  @override
  Future<void> addEntry(String userId, WeightEntry entry) async {
    // If ID exists, update
    final index = _store.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _store[index] = entry;
    } else {
      // simulate new ID if empty
      final newEntry = entry.copyWith(id: entry.id.isEmpty ? 'new_id_${_store.length}' : entry.id);
      _store.add(newEntry);
    }
  }

  @override
  Future<WeightEntry?> getLastEntry(String userId) async {
    if (_store.isEmpty) return null;
    _store.sort((a, b) => b.date.compareTo(a.date));
    return _store.first;
  }

  @override
  Stream<List<WeightEntry>> watchEntries(String userId) {
    return Stream.value(_store);
  }

  // To be implemented in the actual repo
  Future<WeightEntry?> getEntryByDate(String userId, DateTime date) async {
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
  late WeightController controller;
  late MockWeightRepository mockRepo;

  setUp(() {
    mockRepo = MockWeightRepository();
    controller = WeightController(repository: mockRepo, userId: 'test_user');
  });

  test('Initial state should be clean or load last entry', () async {
    expect(controller.weight.value, '');
  });

  test('Should validate input', () async {
    controller.weight.value = '';
    await controller.saveTodayEntry();
    // Assuming the controller handles UI feedback (snackbar), we check if repo has entries
    // Since we can't easily mock Get.snackbar in unit test without more setup,
    // we check the repo state.
    // In current implementation, empty weight prevents saving.
    expect((await mockRepo.getLastEntry('test_user')), isNull);
  });

  test('Should validate negative input', () async {
    controller.weight.value = '-50';
    await controller.saveTodayEntry();
    // Expect no entry to be saved/updated for today
    expect((await mockRepo.getLastEntry('test_user')), isNull);
  });
}
