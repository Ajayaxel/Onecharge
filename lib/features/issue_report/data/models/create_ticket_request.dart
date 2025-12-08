class CreateTicketRequest {
  CreateTicketRequest({
    required this.issueCategoryId,
    required this.vehicleTypeId,
    required this.brandId,
    required this.modelId,
    required this.numberPlate,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.attachments,
  });

  final int issueCategoryId;
  final int vehicleTypeId;
  final int brandId;
  final int modelId;
  final String numberPlate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<String>? attachments;

  Map<String, dynamic> toJson() {
    return {
      'issue_category_id': issueCategoryId,
      'vehicle_type_id': vehicleTypeId,
      'brand_id': brandId,
      'model_id': modelId,
      'number_plate': numberPlate,
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
    };
  }
}

