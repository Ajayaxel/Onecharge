part of 'model_bloc.dart';

sealed class ModelEvent extends Equatable {
  const ModelEvent();

  @override
  List<Object?> get props => [];
}

class ModelsFetched extends ModelEvent {
  const ModelsFetched({
    required this.brandId,
    required this.brandName,
  });

  final int brandId;
  final String brandName;

  @override
  List<Object?> get props => [brandId, brandName];
}

