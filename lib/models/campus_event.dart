import 'package:flutter/material.dart';

import 'time_of_day_utils.dart';

class CampusEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final String location;
  final String category;
  final String? imageUrl;
  final int? capacity;
  final String organizer;
  final DateTime createdAt;

  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.category,
    this.imageUrl,
    this.capacity,
    required this.organizer,
    required this.createdAt,
  });

  factory CampusEvent.fromSupabase(Map<String, dynamic> json) {
    return CampusEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      startTime: parseTimeOfDay(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? parseTimeOfDay(json['end_time'] as String)
          : null,
      location: json['location'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      capacity: json['capacity'] as int?,
      organizer: json['organizer'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
