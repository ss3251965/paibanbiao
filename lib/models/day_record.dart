class DayRecord {
  String shiftId;
  String note;
  bool isDone; // 新增：记录是否完成

  DayRecord({this.shiftId = '', this.note = '', this.isDone = false});

  Map<String, dynamic> toJson() => {
        'shiftId': shiftId,
        'note': note,
        'isDone': isDone,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        shiftId: json['shiftId'] as String? ?? '',
        note: json['note'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );
}