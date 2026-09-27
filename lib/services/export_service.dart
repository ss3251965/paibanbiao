import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shift.dart';
import '../models/day_record.dart';

class ExportService {
  static Future<void> exportCsv({
    required Map<String, DayRecord> records,
    required List<Shift> shifts,
  }) async {
    final nameById = {for (final s in shifts) s.id: s.name};
    final keys = records.keys.toList()..sort();

    final buf = StringBuffer();
    buf.writeln('日期,班次,备注');
    for (final k in keys) {
      final rec = records[k]!;
      final shiftName = rec.shiftId.isEmpty ? '' : (nameById[rec.shiftId] ?? rec.shiftId);
      buf.writeln('$k,$shiftName,${rec.note}');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/banbiao_xiaoli_export.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: '班表小历导出');
  }
}