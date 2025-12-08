class UpdatePasswordRequest {
  UpdatePasswordRequest({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  final String currentPassword;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() => {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
}

