class DayRecord {
  String note;    // 主记录，如“锻炼”
  String detail;  // 详细说明，不显示在主页
  bool isDone;    // 是否已完成

  DayRecord({this.note = '', this.detail = '', this.isDone = false});

  Map<String, dynamic> toJson() => {
        'note': note,
        'detail': detail,
        'isDone': isDone,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        note: json['note'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );
}