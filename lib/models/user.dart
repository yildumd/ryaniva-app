class User {
  final String id;
  final String name;
  final String phone;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
    );
  }
}