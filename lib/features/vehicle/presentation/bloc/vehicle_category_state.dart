part of 'vehicle_category_bloc.dart';

sealed class VehicleCategoryState extends Equatable {
  const VehicleCategoryState();

  @override
  List<Object?> get props => [];
}

final class VehicleCategoryInitial extends VehicleCategoryState {
  const VehicleCategoryInitial();
}

final class VehicleCategoryLoading extends VehicleCategoryState {
  const VehicleCategoryLoading();
}

final class VehicleCategoryLoaded extends VehicleCategoryState {
  const VehicleCategoryLoaded(this.categories);

  final List<VehicleCategory> categories;

  @override
  List<Object?> get props => [categories];
}

final class VehicleCategoryEmpty extends VehicleCategoryState {
  const VehicleCategoryEmpty();
}

final class VehicleCategoryError extends VehicleCategoryState {
  const VehicleCategoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}


