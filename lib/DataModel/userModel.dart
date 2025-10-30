class UserModel {
  final int id;
  final String appAccountToken;
  final String name;
  final String slug;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.appAccountToken,
    required this.name,
    required this.slug,
    required this.email,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      appAccountToken: json['app_account_token'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app_account_token': appAccountToken,
      'name': name,
      'slug': slug,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
