import 'package:flutter/material.dart';

class Shift {
  final String id;
  final String name;
  final String short;
  final int colorValue;

  Shift({
    required this.id,
    required this.name,
    required this.short,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'short': short,
        'colorValue': colorValue,
      };

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        name: json['name'] as String,
        short: json['short'] as String,
        colorValue: json['colorValue'] as int,
      );

  static List<Shift> defaults() => [
        Shift(id: 'morning', name: '早班', short: '早', colorValue: 0xFF34C759),
        Shift(id: 'middle', name: '中班', short: '中', colorValue: 0xFFFF9500),
        Shift(id: 'night', name: '晚班', short: '晚', colorValue: 0xFF5856D6),
        Shift(id: 'rest', name: '休息', short: '休', colorValue: 0xFF8E8E93),
      ];
}