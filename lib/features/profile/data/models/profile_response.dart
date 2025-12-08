import '../../../auth/data/models/login_response.dart';

class ProfileResponse {
  ProfileResponse({
    required this.success,
    required this.customer,
    this.message,
  });

  final bool success;
  final UserModel customer;
  final String? message;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final customerData = data['customer'] as Map<String, dynamic>? ?? {};
    
    return ProfileResponse(
      success: json['success'] as bool? ?? false,
      customer: UserModel.fromJson(customerData),
      message: json['message'] as String?,
    );
  }
}

