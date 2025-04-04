class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['nome'],
      email: json['email'],
      phone: json['phone'] ?? json['telefone'],
      profileImage: json['profile_image'] ?? json['imagem_perfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
    };
  }
}