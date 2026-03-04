import 'package:hive_flutter/hive_flutter.dart';
import '../models/dtr_record.dart';
import '../models/student_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _profileBox = 'profiles';
  static const _recordsBox = 'dtr_records';
  static const _profileKey = 'current_profile';

  // Open both boxes (call once at startup if desired, or lazily here)
  Future<Box> get _profiles async => Hive.isBoxOpen(_profileBox)
      ? Hive.box(_profileBox)
      : await Hive.openBox(_profileBox);

  Future<Box> get _records async => Hive.isBoxOpen(_recordsBox)
      ? Hive.box(_recordsBox)
      : await Hive.openBox(_recordsBox);

  // ── Profile CRUD ────────────────────────────────────────────────────────────

  Future<int> insertProfile(StudentProfile profile) async {
    final box = await _profiles;
    await box.put(_profileKey, profile.toMap());
    return 1;
  }

  Future<StudentProfile?> getProfile() async {
    final box = await _profiles;
    final raw = box.get(_profileKey);
    if (raw == null) return null;
    return StudentProfile.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<int> updateProfile(StudentProfile profile) async {
    final box = await _profiles;
    await box.put(_profileKey, profile.toMap());
    return 1;
  }

  // ── DTR Records CRUD ────────────────────────────────────────────────────────

  /// Insert or replace a record keyed by its date string (yyyy-MM-dd)
  Future<int> insertRecord(DtrRecord record) async {
    final box = await _records;
    await box.put(record.date, record.toMap());
    return 1;
  }

  Future<int> updateRecord(DtrRecord record) async {
    final box = await _records;
    await box.put(record.date, record.toMap());
    return 1;
  }

  Future<DtrRecord?> getRecordByDate(String date) async {
    final box = await _records;
    final raw = box.get(date);
    if (raw == null) return null;
    return DtrRecord.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<DtrRecord>> getAllRecords() async {
    final box = await _records;
    final list = box.values
        .map((e) => DtrRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    // Sort descending by date
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<DtrRecord>> getRecordsByMonth(int year, int month) async {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final box = await _records;
    final list = box.keys
        .where((k) => (k as String).startsWith(prefix))
        .map((k) => DtrRecord.fromMap(Map<String, dynamic>.from(box.get(k) as Map)))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<double> getTotalHours() async {
    final all = await getAllRecords();
    return all
        .where((r) => r.status == 'present')
        .fold<double>(0.0, (sum, r) => sum + (r.hoursWorked ?? 0));
  }

  Future<int> deleteRecord(int id) async {
    // Hive uses date as key — find by matching id field
    final box = await _records;
    String? targetKey;
    for (final key in box.keys) {
      final raw = Map<String, dynamic>.from(box.get(key) as Map);
      if (raw['id'] == id) {
        targetKey = key as String;
        break;
      }
    }
    if (targetKey != null) {
      await box.delete(targetKey);
      return 1;
    }
    return 0;
  }

  /// Delete by date (more efficient since date is the key)
  Future<void> deleteRecordByDate(String date) async {
    final box = await _records;
    await box.delete(date);
  }
}
