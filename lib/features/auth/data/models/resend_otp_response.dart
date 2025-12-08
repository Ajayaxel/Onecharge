class ResendOtpResponse {
  const ResendOtpResponse({
    required this.message,
  });

  final String message;

  factory ResendOtpResponse.fromJson(Map<String, dynamic> json) =>
      ResendOtpResponse(
        message: json['message'] as String? ?? '',
      );
}

