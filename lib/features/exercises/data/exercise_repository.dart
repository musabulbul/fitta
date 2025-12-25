import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/exercise.dart';
import '../models/planned_exercise.dart';
import '../models/set_log.dart';
import '../models/workout_session.dart';

class DayPlan {
  const DayPlan({
    required this.dayKey,
    required this.exercises,
    this.name,
  });

  final String dayKey;
  final List<PlannedExercise> exercises;
  final String? name;
}

class ExerciseRepository {
  ExerciseRepository({
    FirebaseFirestore? firestore,
    HiveInterface? hive,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        hive = hive ?? Hive;

  final FirebaseFirestore firestore;
  final HiveInterface hive;

  static const String todayPlanBox = 'today_plan_cache';
  static const String recentExercisesBox = 'recent_exercises_cache';
  static const List<String> weekDayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const Map<String, String> weekDayLabels = {
    'mon': 'Pzt',
    'tue': 'Sal',
    'wed': 'Çar',
    'thu': 'Per',
    'fri': 'Cum',
    'sat': 'Cmt',
    'sun': 'Paz',
  };

  CollectionReference<Map<String, dynamic>> _plansRef(String userId) =>
      firestore.collection('users').doc(userId).collection('workoutPlans');

  CollectionReference<Map<String, dynamic>> _sessionsRef(String userId) =>
      firestore.collection('users').doc(userId).collection('workoutSessions');

  CollectionReference<Map<String, dynamic>> get _globalExercises =>
      firestore.collection('globalExercises');

  static String dayKeyFromDate(DateTime date) => weekDayKeys[date.weekday - 1];

  Future<DayPlan> getPlanForDay(String userId, String dayKey) async {
    try {
      final doc = await _plansRef(userId).doc(dayKey).get();
      if (!doc.exists) {
        return await _readCachedPlan(dayKey);
      }
      final data = doc.data();
      final exercises = (data?['exercises'] as List?) ?? [];
      final plans = exercises
          .map((e) => PlannedExercise.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      final planName = data?['name'] as String?;
      await _cachePlan(dayKey, plans, planName);
      return DayPlan(dayKey: dayKey, exercises: plans, name: planName);
    } catch (e) {
      final cached = await _readCachedPlan(dayKey);
      if (cached.exercises.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<DayPlan> getTodayPlan(String userId, DateTime date) =>
      getPlanForDay(userId, dayKeyFromDate(date));

  Future<void> savePlanForDays({
    required String userId,
    required List<String> dayKeys,
    required List<PlannedExercise> exercises,
    String? planName,
  }) async {
    final batch = firestore.batch();
    final Map<String, dynamic> payload = {
      'name': planName?.isEmpty == true ? null : planName,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    for (final day in dayKeys) {
      batch.set(_plansRef(userId).doc(day), {...payload, 'day': day});
      await _cachePlan(day, exercises, planName);
    }
    await batch.commit();
  }

  Future<void> updatePlanForDay({
    required String userId,
    required String dayKey,
    required List<PlannedExercise> exercises,
    String? planName,
  }) async {
    final Map<String, dynamic> payload = {
      'day': dayKey,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (planName != null) {
      payload['name'] = planName.isEmpty ? null : planName;
    }
    await _plansRef(userId).doc(dayKey).set(payload, SetOptions(merge: true));
    await _cachePlan(dayKey, exercises, planName);
  }

  Future<void> saveWorkoutSession({
    required String userId,
    required String planId,
    required DateTime date,
    required List<PlannedExercise> planned,
    required Map<String, List<SetLog>> logsByExerciseId,
    required Map<String, double?> nextWeights,
    List<PlannedExercise>? planForCache,
  }) async {
    try {
      final planRef = _plansRef(userId).doc(planId);
      final existingSession = await _findSessionForDay(userId, planId, date);
      final sessionRef = existingSession?.reference ?? _sessionsRef(userId).doc();
      final existingData = existingSession?.data() as Map<String, dynamic>? ?? {};
      final existingExercises = ((existingData['exercises'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final existingMap = {
        for (final e in existingExercises)
          (e['exerciseId'] as String? ?? ''): e,
      };

      for (final plan in planned) {
        final logs = logsByExerciseId[plan.exerciseId] ?? <SetLog>[];
        existingMap[plan.exerciseId] = {
          'exerciseId': plan.exerciseId,
          'name': plan.name,
          'plannedSets': plan.sets,
          'plannedReps': plan.reps,
          'plannedWeight': plan.type == 'time' ? null : (plan.weight ?? plan.nextWeight),
          'plannedSeconds': plan.type == 'time' ? (plan.seconds ?? plan.reps) : null,
          'logs': logs.map((l) => l.toMap()).toList(),
        };
      }

      final sessionData = {
        'id': sessionRef.id,
        'date': Timestamp.fromDate(date),
        'planId': planId,
        'exercises': existingMap.values.toList(),
      };

      await sessionRef.set(sessionData, SetOptions(merge: true));

      if (nextWeights.isNotEmpty) {
        final planSnap = await planRef.get();
        final planData = planSnap.data() as Map<String, dynamic>? ?? {};
        final existingExercises = ((planData['exercises'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final updatedExercises = existingExercises.map((exercise) {
          final id = exercise['exerciseId'] as String? ?? '';
          if (nextWeights.containsKey(id)) {
            final weight = nextWeights[id];
            final type = exercise['type'] as String? ?? 'weight';
            if (type == 'time') {
              exercise['seconds'] = weight?.toInt();
              exercise['nextWeight'] = null;
              exercise['weight'] = null;
            } else {
              exercise['weight'] = weight;
              exercise['nextWeight'] = weight;
            }
          }
          return exercise;
        }).toList();

        await planRef.set(
          {
            ...planData,
            'exercises': updatedExercises,
          },
          SetOptions(merge: true),
        );
      }

      final cacheList = planForCache ?? planned;
      await _cachePlan(planId, cacheList, null);
      await _cacheRecentExercises(cacheList);
    } catch (e, stack) {
      final inner = _innerError(e);
      final innerStack = _innerStack(e);
      final innerType = inner?.runtimeType;
      final nativeDetails = _describeNativeError(e);
      log(
        'saveWorkoutSession failed (planId=$planId, user=$userId, type=${e.runtimeType}, innerType=$innerType, innerError=$inner, innerStack=$innerStack, native=$nativeDetails, planned=${_describePlanned(planned)}, logs=${_describeLogs(logsByExerciseId)}, next=$nextWeights)',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<WorkoutSession?> getLatestSessionForPlan({
    required String userId,
    required String planId,
  }) async {
    final snap = await _sessionsRef(userId)
        .where('planId', isEqualTo: planId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return WorkoutSession.fromMap({'id': doc.id, ...doc.data()});
  }

  String _describePlanned(List<PlannedExercise> planned) {
    return planned
        .map((p) => {
              'id': p.exerciseId,
              'name': p.name,
              'sets': p.sets,
              'reps': p.reps,
              'weight': p.weight,
              'seconds': p.seconds,
              'type': p.type,
              'nextWeight': p.nextWeight,
            })
        .toList()
        .toString();
  }

  String _describeLogs(Map<String, List<SetLog>> logs) {
    return logs.map((k, v) => MapEntry(k, v.map((l) => l.toMap()).toList())).toString();
  }

  Object? _innerError(Object e) {
    try {
      return (e as dynamic).error as Object?;
    } catch (_) {
      return null;
    }
  }

  StackTrace? _innerStack(Object e) {
    try {
      return (e as dynamic).stack as StackTrace?;
    } catch (_) {
      return null;
    }
  }

  String _describeNativeError(Object e) {
    if (e.runtimeType.toString() != 'NativeError') return '';
    final buffer = StringBuffer();
    try {
      final inner = (e as dynamic).error;
      buffer.write('error=$inner');
      try {
        buffer.write(', code=${(inner as dynamic).code}');
      } catch (_) {}
      try {
        buffer.write(', message=${(inner as dynamic).message}');
      } catch (_) {}
      try {
        buffer.write(', name=${(inner as dynamic).name}');
      } catch (_) {}
      try {
        buffer.write(', stack=${(inner as dynamic).stack}');
      } catch (_) {}
    } catch (_) {}
    return buffer.toString();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findSessionForDay(
    String userId,
    String planId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _sessionsRef(userId)
        .where('planId', isEqualTo: planId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Future<List<WorkoutSession>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 20,
  }) async {
    final snap = await _sessionsRef(userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();

    final sessions = snap.docs.map((doc) {
      final data = doc.data();
      return WorkoutSession.fromMap({'id': doc.id, ...data});
    }).toList();

    return sessions
        .map((s) => s.copyWith(
              exercises: s.exercises
                  .where((e) => e.exerciseId == exerciseId)
                  .toList(),
            ))
        .where((s) => s.exercises.isNotEmpty)
        .toList();
  }

  Future<void> deleteWorkoutSession({
    required String userId,
    required String sessionId,
  }) async {
    await _sessionsRef(userId).doc(sessionId).delete();
  }

  Future<List<Exercise>> searchExercises({
    required String query,
    String? category,
  }) async {
    final trimmed = query.trim().toLowerCase();
    Query<Map<String, dynamic>> base = _globalExercises;
    if (category != null && category.isNotEmpty) {
      base = base.where('category', isEqualTo: category);
    }

    Future<List<Exercise>> _fetch(Query<Map<String, dynamic>> q) async {
      final snap = await q.limit(50).get();
      return snap.docs.map((doc) => Exercise.fromMap({'id': doc.id, ...doc.data()})).toList();
    }

    try {
      Query<Map<String, dynamic>> primary = base;
      if (trimmed.isNotEmpty) {
        primary = primary.where('keywords', arrayContains: trimmed);
      }
      var results = await _fetch(primary);

      if (trimmed.isNotEmpty && results.isEmpty) {
        // Fallback: fetch by category only and filter by name locally.
        final fallback = await _fetch(base);
        results = fallback
            .where((e) => e.name.toLowerCase().contains(trimmed))
            .toList();
      }
      return results;
    } catch (_) {
      final cached = await _readCachedExercises();
      if (cached.isNotEmpty && trimmed.isNotEmpty) {
        return cached.where((e) => e.name.toLowerCase().contains(trimmed)).toList();
      }
      return cached;
    }
  }

  Future<void> _cachePlan(String dayKey, List<PlannedExercise> plans, String? name) async {
    try {
      final box = await _openBox(todayPlanBox);
      await box.put(
        'plans_$dayKey',
        {
          'name': name,
          'list': plans.map((e) => e.toMap()).toList(),
        },
      );
    } catch (_) {
      // Cache failures should not block flow.
    }
  }

  Future<DayPlan> _readCachedPlan(String dayKey) async {
    try {
      if (!await hive.boxExists(todayPlanBox)) {
        return DayPlan(dayKey: dayKey, exercises: const [], name: null);
      }
      final box = await _openBox(todayPlanBox);
      final cached = box.get('plans_$dayKey');
      if (cached is Map) {
        final name = cached['name'] as String?;
        final list = cached['list'] as List?;
        final plans = (list ?? [])
            .map((e) => PlannedExercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        return DayPlan(dayKey: dayKey, exercises: plans, name: name);
      }
      return DayPlan(dayKey: dayKey, exercises: const [], name: null);
    } catch (_) {
      return DayPlan(dayKey: dayKey, exercises: const [], name: null);
    }
  }

  Future<void> _cacheRecentExercises(List<PlannedExercise> plans) async {
    try {
      final box = await _openBox(recentExercisesBox);
      await box.put(
        'list',
        plans.map((p) => {'id': p.exerciseId, 'name': p.name}).toList(),
      );
    } catch (_) {
      // Ignore cache errors.
    }
  }

  Future<List<Exercise>> _readCachedExercises() async {
    try {
      if (!await hive.boxExists(recentExercisesBox)) return [];
      final box = await _openBox(recentExercisesBox);
      final list = box.get('list') as List?;
      return (list ?? []).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        map['id'] = map['id'] ?? map['exerciseId'];
        return Exercise.fromMap(map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Box> _openBox(String name) async {
    if (hive.isBoxOpen(name)) {
      return hive.box(name);
    }
    return hive.openBox(name);
  }
}
