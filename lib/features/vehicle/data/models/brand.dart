import 'package:equatable/equatable.dart';
import 'submodel.dart';

class Brand extends Equatable {
  const Brand({
    required this.id,
    required this.name,
    required this.logo,
    this.categoryId,
    this.submodels = const [],
  });

  final int id;
  final String name;
  final String logo;
  final int? categoryId;
  final List<SubModel> submodels;

  factory Brand.fromJson(Map<String, dynamic> json) {
    final submodelsJson = json['submodels'] as List<dynamic>? ?? [];
    final submodels = submodelsJson
        .whereType<Map<String, dynamic>>()
        .map((submodelJson) => SubModel.fromJson(submodelJson))
        .toList();

    // Handle both 'logo' and 'image' fields (API uses 'image', can be null)
    final logo = json['logo'] as String? ?? json['image'] as String? ?? '';
    
    // Handle both 'category_id' and 'vehicle_type_id' fields
    final categoryId = (json['category_id'] as num?)?.toInt() ?? 
                       (json['vehicle_type_id'] as num?)?.toInt();

    return Brand(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      logo: logo.trim(),
      categoryId: categoryId,
      submodels: submodels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      if (categoryId != null) 'category_id': categoryId,
      'submodels': submodels.map((submodel) => submodel.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, logo, categoryId, submodels];
}

