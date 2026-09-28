enum UserRole { customer, partner, driver }

UserRole userRoleFromString(String value) {
  switch (value.toUpperCase()) {
    case 'PARTNER':
      return UserRole.partner;
    case 'DRIVER':
      return UserRole.driver;
    case 'CUSTOMER':
    default:
      return UserRole.customer;
  }
}

String userRoleToApiString(UserRole role) {
  switch (role) {
    case UserRole.partner:
      return 'PARTNER';
    case UserRole.driver:
      return 'DRIVER';
    case UserRole.customer:
      return 'CUSTOMER';
  }
}

class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: (json['name'] ?? '') as String,
      phone: json['phone'] as String?,
      role: userRoleFromString((json['role'] ?? 'CUSTOMER') as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': userRoleToApiString(role),
    };
  }

  User copyWith({String? name, String? phone}) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role,
    );
  }
}
