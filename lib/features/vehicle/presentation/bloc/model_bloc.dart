import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/submodel.dart';
import '../../data/repositories/model_repository.dart';
import '../../../../core/error/api_exception.dart';

part 'model_event.dart';
part 'model_state.dart';

class ModelBloc extends Bloc<ModelEvent, ModelState> {
  ModelBloc(this._repository) : super(ModelInitial()) {
    on<ModelsFetched>(_onModelsFetched);
  }

  final ModelRepository _repository;

  Future<void> _onModelsFetched(
    ModelsFetched event,
    Emitter<ModelState> emit,
  ) async {
    print('🟢 [ModelBloc] ModelsFetched event received for brandId: ${event.brandId}, name: ${event.brandName}');
    emit(ModelLoading());
    print('🟡 [ModelBloc] State changed to ModelLoading');
    
    try {
      print('🔵 [ModelBloc] Calling repository.getModelsByBrand(id: ${event.brandId}, name: ${event.brandName})');
      final models = await _repository.getModelsByBrand(
        brandId: event.brandId,
        brandName: event.brandName,
      );
      print('🔵 [ModelBloc] Repository returned ${models.length} models');
      
      if (models.isEmpty) {
        print('🟡 [ModelBloc] No models found, emitting ModelEmpty');
        emit(const ModelEmpty());
        return;
      }
      print('✅ [ModelBloc] Emitting ModelLoaded with ${models.length} models');
      emit(ModelLoaded(models));
    } on ApiException catch (error) {
      print('❌ [ModelBloc] ApiException caught: ${error.message}');
      print('❌ [ModelBloc] Status code: ${error.statusCode}');
      emit(ModelError(error.message));
    } catch (e, stackTrace) {
      print('❌ [ModelBloc] Unexpected error: $e');
      print('❌ [ModelBloc] Stack trace: $stackTrace');
      emit(const ModelError('Unable to load models.'));
    }
  }
}

