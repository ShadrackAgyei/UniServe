class StudyRoom {
  final String id;
  final String name;
  final String building;
  final int floor;
  final int capacity;
  final List<String> facilities;
  final String? imageUrl;

  StudyRoom({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.facilities,
    this.imageUrl,
  });

  factory StudyRoom.fromSupabase(Map<String, dynamic> json) {
    return StudyRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      building: json['building'] as String,
      floor: json['floor'] as int,
      capacity: json['capacity'] as int,
      facilities: List<String>.from(json['facilities'] as List? ?? []),
      imageUrl: json['image_url'] as String?,
    );
  }
}
