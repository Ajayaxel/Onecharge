class VerifyOtpResponse {
  const VerifyOtpResponse({
    required this.message,
  });

  final String message;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        message: json['message'] as String? ?? '',
      );
}

