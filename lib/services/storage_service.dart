import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_record.dart';

class StorageService {
  static const _kRecords = 'records_v1';

  Future<Map<String, DayRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecords);

    if (raw == null) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;

      return map.map(
        (k, v) => MapEntry(
          k,
          DayRecord.fromJson(
            v as Map<String, dynamic>,
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRecords(
    Map<String, DayRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final map = records.map(
      (k, v) => MapEntry(
        k,
        v.toJson(),
      ),
    );

    await prefs.setString(
      _kRecords,
      jsonEncode(map),
    );
  }
}