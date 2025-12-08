import 'package:equatable/equatable.dart';

class BrandModel extends Equatable {
  const BrandModel({
    required this.id,
    required this.name,
    this.vehicleTypeId,
  });

  final int id;
  final String name;
  final int? vehicleTypeId;

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      vehicleTypeId: (json['vehicle_type_id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
    };
  }

  @override
  List<Object?> get props => [id, name, vehicleTypeId];
}

