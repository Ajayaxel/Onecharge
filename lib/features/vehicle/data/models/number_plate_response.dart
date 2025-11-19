class NumberPlateResponse {
  NumberPlateResponse({required this.status, required this.message, this.data});

  final bool status;
  final String message;
  final NumberPlateData? data;

  factory NumberPlateResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return NumberPlateResponse(
      status: json['status'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: dataJson is Map<String, dynamic>
          ? NumberPlateData.fromJson(dataJson)
          : null,
    );
  }
}

class NumberPlateData {
  NumberPlateData({
    required this.id,
    required this.plateNumber,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String plateNumber;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NumberPlateData.fromJson(Map<String, dynamic> json) {
    return NumberPlateData(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      plateNumber: json['plate_number']?.toString() ?? '',
      image: json['image']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
