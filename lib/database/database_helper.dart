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

  /// Insert a record and return its id
  Future<int> insertRecord(DtrRecord record) async {
    final box = await _records;
    // If record doesn't have an ID, generate one
    final idForRecord = record.id ?? DateTime.now().millisecondsSinceEpoch;
    final updatedRecord = record.copyWith(id: idForRecord);
    await box.put(idForRecord.toString(), updatedRecord.toMap());
    return idForRecord;
  }

  Future<int> updateRecord(DtrRecord record) async {
    if (record.id == null) return 0;
    final box = await _records;
    await box.put(record.id.toString(), record.toMap());
    return 1;
  }

  /// Get the latest record for a specific date that isn't clocked out yet
  Future<DtrRecord?> getActiveRecordByDate(String date) async {
    final box = await _records;
    final records = box.values
        .map((e) => DtrRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((r) => r.date == date && r.timeOut == null)
        .toList();
    
    if (records.isEmpty) return null;
    // Return latest active one
    return records.last;
  }

  /// Get all records for a specific date
  Future<List<DtrRecord>> getRecordsByDate(String date) async {
    final box = await _records;
    return box.values
        .map((e) => DtrRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((r) => r.date == date)
        .toList();
  }

  Future<List<DtrRecord>> getAllRecords() async {
    final box = await _records;
    final list = box.values
        .map((e) => DtrRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    // Sort descending by date, then by timeIn
    list.sort((a, b) {
      int dateComp = b.date.compareTo(a.date);
      if (dateComp != 0) return dateComp;
      return (b.timeIn ?? '').compareTo(a.timeIn ?? '');
    });
    return list;
  }

  Future<List<DtrRecord>> getRecordsByMonth(int year, int month) async {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final box = await _records;
    final list = box.values
        .map((e) => DtrRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .where((r) => r.date.startsWith(prefix))
        .toList();
    
    list.sort((a, b) {
      int dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return (a.timeIn ?? '').compareTo(b.timeIn ?? '');
    });
    return list;
  }

  Future<double> getTotalHours() async {
    final all = await getAllRecords();
    return all
        .where((r) => r.status == 'present' || r.status == 'half-day')
        .fold<double>(0.0, (sum, r) => sum + (r.hoursWorked ?? 0));
  }

  Future<int> deleteRecord(int id) async {
    final box = await _records;
    if (box.containsKey(id.toString())) {
      await box.delete(id.toString());
      return 1;
    }
    // Fallback for old records where key might be the date
    String? keyToRemove;
    for (var key in box.keys) {
      final raw = box.get(key);
      if (raw != null && Map<String, dynamic>.from(raw as Map)['id'] == id) {
        keyToRemove = key as String;
        break;
      }
    }
    if (keyToRemove != null) {
      await box.delete(keyToRemove);
      return 1;
    }
    return 0;
  }

  /// Delete all records for a date (legacy support/utility)
  Future<void> deleteRecordsByDate(String date) async {
    final box = await _records;
    final keysToDelete = box.keys.where((k) {
      final record = DtrRecord.fromMap(Map<String, dynamic>.from(box.get(k) as Map));
      return record.date == date;
    }).toList();

    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }
}
