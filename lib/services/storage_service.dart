import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift.dart';
import '../models/day_record.dart';

class StorageService {
  static const _kShifts = 'shifts_v1';
  static const _kRecords = 'records_v1';

  Future<List<Shift>> loadShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kShifts);
    if (raw == null) return Shift.defaults();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Shift.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return Shift.defaults();
    }
  }

  Future<void> saveShifts(List<Shift> shifts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShifts, jsonEncode(shifts.map((e) => e.toJson()).toList()));
  }

  Future<Map<String, DayRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecords);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, DayRecord.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRecords(Map<String, DayRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final map = records.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kRecords, jsonEncode(map));
  }
}