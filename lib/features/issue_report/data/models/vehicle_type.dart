import 'package:equatable/equatable.dart';

class VehicleType extends Equatable {
  const VehicleType({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object> get props => [id, name];
}

