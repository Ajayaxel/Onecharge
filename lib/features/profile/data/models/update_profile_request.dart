class UpdateProfileRequest {
  UpdateProfileRequest({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };
}

