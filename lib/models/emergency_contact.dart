class EmergencyContact {
  final int? id;
  final String name;
  final String phone;
  final String department;
  final String icon;
  final int sortOrder;

  const EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    required this.department,
    required this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'department': department,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      department: map['department'] as String,
      icon: map['icon'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  factory EmergencyContact.fromSupabase(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      department: json['department'] as String,
      icon: json['icon'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
