import 'package:flutter/material.dart';

import 'time_of_day_utils.dart';

class ClassEntry {
  final String id;
  final String userId;
  final String courseName;
  final String courseCode;
  final String room;
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? lecturer;
  final String colorHex;

  ClassEntry({
    required this.id,
    required this.userId,
    required this.courseName,
    required this.courseCode,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.lecturer,
    required this.colorHex,
  }) : assert(dayOfWeek >= 0 && dayOfWeek <= 6, 'dayOfWeek must be 0–6 (Mon–Sun)');

  factory ClassEntry.fromSupabase(Map<String, dynamic> json) {
    return ClassEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseName: json['course_name'] as String,
      courseCode: json['course_code'] as String,
      room: json['room'] as String,
      dayOfWeek: json['day_of_week'] as int,
      startTime: parseTimeOfDay(json['start_time'] as String),
      endTime: parseTimeOfDay(json['end_time'] as String),
      lecturer: json['lecturer'] as String?,
      colorHex: json['color_hex'] as String,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'user_id': userId,
        'course_name': courseName,
        'course_code': courseCode,
        'room': room,
        'day_of_week': dayOfWeek,
        'start_time': formatTimeOfDay(startTime),
        'end_time': formatTimeOfDay(endTime),
        'lecturer': lecturer,
        'color_hex': colorHex,
      };
}
