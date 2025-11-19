class RegisterResponse {
  RegisterResponse({
    required this.message,
    required this.user,
  });

  final String message;
  final RegisterUserModel user;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        message: json['message'] as String? ?? '',
        user: RegisterUserModel.fromJson(
          json['user'] as Map<String, dynamic>? ?? {},
        ),
      );
}

class RegisterUserModel {
  const RegisterUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.verificationToken,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? verificationToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RegisterUserModel.fromJson(Map<String, dynamic> json) {
    return RegisterUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      verificationToken: json['verification_token'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

