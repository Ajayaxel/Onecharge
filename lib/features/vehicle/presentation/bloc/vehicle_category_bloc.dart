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
      print('🟢 [VehicleCategoryBloc] Fetching vehicle categories...');
      final categories = await _repository.getVehicleCategories();
      print('✅ [VehicleCategoryBloc] Received ${categories.length} categories');
      if (categories.isEmpty) {
        print('⚠️ [VehicleCategoryBloc] Categories list is empty');
        emit(const VehicleCategoryEmpty());
        return;
      }
      print('✅ [VehicleCategoryBloc] Emitting VehicleCategoryLoaded with ${categories.length} categories');
      emit(VehicleCategoryLoaded(categories));
    } on ApiException catch (error) {
      print('❌ [VehicleCategoryBloc] ApiException: ${error.message}');
      emit(VehicleCategoryError(error.message));
    } catch (e) {
      print('❌ [VehicleCategoryBloc] Unexpected error: $e');
      emit(const VehicleCategoryError('Unable to load vehicle categories.'));
    }
  }
}


