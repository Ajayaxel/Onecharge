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
    return SubModel(
      submodelId: (json['submodel_id'] as num?)?.toInt() ?? 0,
      submodelName: (json['submodel_name'] as String? ?? '').trim(),
      submodelImage: (json['submodel_image'] as String? ?? '').trim(),
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

