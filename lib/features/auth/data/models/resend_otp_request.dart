class ResendOtpRequest {
  const ResendOtpRequest({
    required this.email,
  });

  final String email;

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}

