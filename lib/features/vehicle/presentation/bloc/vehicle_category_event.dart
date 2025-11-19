part of 'vehicle_category_bloc.dart';

sealed class VehicleCategoryEvent extends Equatable {
  const VehicleCategoryEvent();

  @override
  List<Object?> get props => [];
}

class VehicleCategoriesFetched extends VehicleCategoryEvent {
  const VehicleCategoriesFetched();
}


