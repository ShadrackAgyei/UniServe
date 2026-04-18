class CampusNotification {
  final int? id;
  final String title;
  final String message;
  final String category;
  final DateTime createdAt;
  final bool isRead;

  CampusNotification({
    this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory CampusNotification.fromMap(Map<String, dynamic> map) {
    return CampusNotification(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      category: map['category'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int?) == 1,
    );
  }

  factory CampusNotification.fromSupabase(Map<String, dynamic> json) {
    return CampusNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
