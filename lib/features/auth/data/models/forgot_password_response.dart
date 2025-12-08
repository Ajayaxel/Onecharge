class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? '',
      );
}

