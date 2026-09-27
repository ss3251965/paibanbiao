import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/day_record.dart';

class ExportService {
  static Future<void> exportCsv({
    required Map<String, DayRecord> records,
    required List<dynamic> shifts, // 保留参数为了兼容，但不再使用
  }) async {
    final keys = records.keys.toList()..sort();

    final buf = StringBuffer();
    // 更新了表头，去掉了班次，增加了详细说明
    buf.writeln('日期,记录,详细说明,是否完成');
    for (final k in keys) {
      final rec = records[k]!;
      final doneText = rec.isDone ? '是' : '否';
      buf.writeln('$k,${rec.note},${rec.detail},$doneText');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/banbiao_xiaoli_export.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: '班表小历导出');
  }
}