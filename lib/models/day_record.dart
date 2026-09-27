class DayRecord {
  String note;        // 主记录（如：锻炼）
  String detail;      // 详细说明（不显示在主页）
  bool isDone;        // 是否完成
  bool hasRingtone;   // 是否需要铃声
  String ringtoneType; // 铃声类型：默认、通知、闹钟
  String reminderTime; // 提醒时间，格式 "HH:mm"

  DayRecord({
    this.note = '', 
    this.detail = '', 
    this.isDone = false,
    this.hasRingtone = false,
    this.ringtoneType = '默认',
    this.reminderTime = '08:00',
  });

  Map<String, dynamic> toJson() => {
        'note': note,
        'detail': detail,
        'isDone': isDone,
        'hasRingtone': hasRingtone,
        'ringtoneType': ringtoneType,
        'reminderTime': reminderTime,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        note: json['note'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
        hasRingtone: json['hasRingtone'] as bool? ?? false,
        ringtoneType: json['ringtoneType'] as String? ?? '默认',
        reminderTime: json['reminderTime'] as String? ?? '08:00',
      );
}