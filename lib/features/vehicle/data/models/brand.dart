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

    return Brand(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      logo: (json['logo'] as String? ?? '').trim(),
      categoryId: (json['category_id'] as num?)?.toInt(),
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

