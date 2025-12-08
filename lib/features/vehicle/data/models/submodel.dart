import 'package:equatable/equatable.dart';

class SubModel extends Equatable {
  const SubModel({
    required this.submodelId,
    required this.submodelName,
    required this.submodelImage,
  });

  final int submodelId;
  final String submodelName;
  final String submodelImage;

  factory SubModel.fromJson(Map<String, dynamic> json) {
    // Handle both old format (submodel_id, submodel_name, submodel_image) 
    // and new format (id, name, image, brand_id)
    final id = (json['id'] as num?)?.toInt() ?? 
               (json['submodel_id'] as num?)?.toInt() ?? 0;
    final name = (json['name'] as String? ?? json['submodel_name'] as String? ?? '').trim();
    final image = (json['image'] as String? ?? json['submodel_image'] as String? ?? '').trim();
    
    return SubModel(
      submodelId: id,
      submodelName: name,
      submodelImage: image,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submodel_id': submodelId,
      'submodel_name': submodelName,
      'submodel_image': submodelImage,
    };
  }

  @override
  List<Object?> get props => [submodelId, submodelName, submodelImage];
}

