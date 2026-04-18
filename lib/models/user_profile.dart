class UserProfile {
  final String? id; // UUID from Supabase auth
  final String studentId;
  final String name;
  final String email;
  final String? phone;
  final String? department;
  final String? program;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  UserProfile({
    this.id,
    required this.studentId,
    required this.name,
    required this.email,
    this.phone,
    this.department,
    this.program,
    this.profilePhotoUrl,
    this.createdAt,
  });

  factory UserProfile.fromSupabase(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      program: json['program'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'program': program,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      studentId: json['student_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      program: json['program'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? department,
    String? program,
    String? profilePhotoUrl,
  }) {
    return UserProfile(
      id: id,
      studentId: studentId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      program: program ?? this.program,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt,
    );
  }
}
