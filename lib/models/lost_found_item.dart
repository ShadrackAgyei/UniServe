class LostFoundItem {
  final int? id;
  final String? userId;
  final String title;
  final String description;
  final String type; // 'lost' or 'found'
  final String? reporterName;
  final String? imageUrl;
  final String location;
  final String contactInfo;
  final DateTime createdAt;
  final bool isResolved;

  LostFoundItem({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.type,
    this.reporterName,
    this.imageUrl,
    required this.location,
    required this.contactInfo,
    required this.createdAt,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type,
      'reporter_name': reporterName,
      'image_url': imageUrl,
      'location': location,
      'contact_info': contactInfo,
      'created_at': createdAt.toIso8601String(),
      'is_resolved': isResolved ? 1 : 0,
    };
  }

  factory LostFoundItem.fromMap(Map<String, dynamic> map) {
    return LostFoundItem(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      type: map['type'] as String,
      reporterName: map['reporter_name'] as String?,
      imageUrl: map['image_url'] as String?,
      location: map['location'] as String,
      contactInfo: map['contact_info'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isResolved: (map['is_resolved'] as int?) == 1,
    );
  }

  factory LostFoundItem.fromSupabase(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'] as int,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      reporterName: json['reporter_name'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String,
      contactInfo: json['contact_info'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isResolved: json['is_resolved'] as bool? ?? false,
    );
  }
}
