class UpdatePasswordResponse {
  UpdatePasswordResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory UpdatePasswordResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

