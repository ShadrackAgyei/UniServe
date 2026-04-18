class CampusIssue {
  final int? id;
  final String? userId;
  final String title;
  final String description;
  final String category;
  final String? reporterName;
  final String? imageUrl;
  final DateTime createdAt;
  final String status;

  CampusIssue({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.reporterName,
    this.imageUrl,
    required this.createdAt,
    this.status = 'Pending',
  });

  /// For local sqflite cache
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'reporter_name': reporterName,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// From local sqflite cache
  factory CampusIssue.fromMap(Map<String, dynamic> map) {
    return CampusIssue(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      reporterName: map['reporter_name'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: map['status'] as String? ?? 'Pending',
    );
  }

  /// From Supabase JSON response
  factory CampusIssue.fromSupabase(Map<String, dynamic> json) {
    return CampusIssue(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      reporterName: json['reporter_name'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'Pending',
    );
  }
}
