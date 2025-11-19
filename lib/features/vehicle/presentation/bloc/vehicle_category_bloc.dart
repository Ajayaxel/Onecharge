import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/vehicle_category.dart';
import '../../data/repositories/vehicle_category_repository.dart';
import '../../../../core/error/api_exception.dart';

part 'vehicle_category_event.dart';
part 'vehicle_category_state.dart';

class VehicleCategoryBloc
    extends Bloc<VehicleCategoryEvent, VehicleCategoryState> {
  VehicleCategoryBloc(this._repository) : super(VehicleCategoryInitial()) {
    on<VehicleCategoriesFetched>(_onVehicleCategoriesFetched);
  }

  final VehicleCategoryRepository _repository;

  Future<void> _onVehicleCategoriesFetched(
    VehicleCategoriesFetched event,
    Emitter<VehicleCategoryState> emit,
  ) async {
    emit(VehicleCategoryLoading());
    try {
      final categories = await _repository.getVehicleCategories();
      if (categories.isEmpty) {
        emit(const VehicleCategoryEmpty());
        return;
      }
      emit(VehicleCategoryLoaded(categories));
    } on ApiException catch (error) {
      emit(VehicleCategoryError(error.message));
    } catch (_) {
      emit(const VehicleCategoryError('Unable to load vehicle categories.'));
    }
  }
}


