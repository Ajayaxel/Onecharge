import 'package:equatable/equatable.dart';

class VehicleCategory extends Equatable {
  const VehicleCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory VehicleCategory.fromJson(Map<String, dynamic> json) {
    return VehicleCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  @override
  List<Object> get props => [id, name];
}


