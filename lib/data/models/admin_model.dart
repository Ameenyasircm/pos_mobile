class AdminModel {
  final String id;
  final String name;
  final String phone;
  final String password;
  final String role;
  final bool isActive;
  final dynamic lastLogin;

  AdminModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    required this.isActive,
    this.lastLogin,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String id) {
    return AdminModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'admin',
      isActive: map['isActive'] ?? true,
      lastLogin: map['lastLogin'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      'isActive': isActive,
      'lastLogin': lastLogin,
    };
  }

  AdminModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? password,
    String? role,
    bool? isActive,
    dynamic lastLogin,
  }) {
    return AdminModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
