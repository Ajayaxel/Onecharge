class LoginResponse {
  LoginResponse({
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
    required this.expiresIn,
  });

  final String message;
  final UserModel user;
  final String token;
  final String tokenType;
  final int expiresIn;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        message: json['message'] as String? ?? '',
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
        token: json['token'] as String? ?? '',
        tokenType: json['token_type'] as String? ?? '',
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      );
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String?,
      emailVerifiedAt: _parseDate(json['email_verified_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}


