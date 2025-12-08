import 'package:equatable/equatable.dart';

class ModelItem extends Equatable {
  const ModelItem({
    required this.id,
    required this.name,
    this.brandId,
  });

  final int id;
  final String name;
  final int? brandId;

  factory ModelItem.fromJson(Map<String, dynamic> json) {
    return ModelItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      brandId: (json['brand_id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (brandId != null) 'brand_id': brandId,
    };
  }

  @override
  List<Object?> get props => [id, name, brandId];
}

