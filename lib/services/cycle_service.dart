import '../models/day_record.dart';

class CycleService {
  static Map<String, DayRecord> generate({
    required DateTime start,
    required DateTime end,
    required List<String?> cycle,
  }) {
    final result = <String, DayRecord>{};
    if (cycle.isEmpty) return result;

    var cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    var index = 0;

    while (!cursor.isAfter(endDay)) {
      final shiftText = cycle[index % cycle.length];
      if (shiftText != null && shiftText.isNotEmpty) {
        // 修复：使用新的 DayRecord 结构，直接存入 note
        result[_key(cursor)] = DayRecord(note: shiftText);
      }
      cursor = cursor.add(const Duration(days: 1));
      index++;
    }
    return result;
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}