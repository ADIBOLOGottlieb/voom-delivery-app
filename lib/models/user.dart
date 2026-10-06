class UserRole {
  static const client = 'client';
  static const courier = 'livreur';
  static const admin = 'admin';
}

class User {
  final int id;
  final String name;
  final String? email;
  final String phoneNumber;
  final String role;
  final String? vehicle;

  const User({
    required this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    required this.role,
    this.vehicle,
  });

  bool get isCourier => role == UserRole.courier;
  bool get isClient => role == UserRole.client;

  String get roleLabel => switch (role) {
        UserRole.courier => 'Livreur',
        UserRole.admin => 'Administrateur',
        _ => 'Client',
      };

  String get initial => name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        phoneNumber: json['phone_number'] as String,
        role: json['role'] as String,
        vehicle: json['vehicle'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'vehicle': vehicle,
      };
}
