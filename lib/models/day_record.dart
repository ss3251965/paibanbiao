class DayRecord {
  String shiftId;
  String note;

  DayRecord({this.shiftId = '', this.note = ''});

  Map<String, dynamic> toJson() => {
        'shiftId': shiftId,
        'note': note,
      };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
        shiftId: json['shiftId'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}