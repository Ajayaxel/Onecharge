import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/brand.dart';
import '../../data/repositories/brand_repository.dart';
import '../../../../core/error/api_exception.dart';

part 'brand_event.dart';
part 'brand_state.dart';

class BrandBloc extends Bloc<BrandEvent, BrandState> {
  BrandBloc(this._repository) : super(BrandInitial()) {
    on<BrandsFetched>(_onBrandsFetched);
  }

  final BrandRepository _repository;

  Future<void> _onBrandsFetched(
    BrandsFetched event,
    Emitter<BrandState> emit,
  ) async {
    print('🟢 [BrandBloc] BrandsFetched event received for categoryId: ${event.categoryId}, name: ${event.categoryName}');
    emit(BrandLoading());
    print('🟡 [BrandBloc] State changed to BrandLoading');
    
    try {
      print('🔵 [BrandBloc] Calling repository.getBrandsByCategory(id: ${event.categoryId}, name: ${event.categoryName})');
      final brands = await _repository.getBrandsByCategory(
        categoryId: event.categoryId,
        categoryName: event.categoryName,
      );
      print('🔵 [BrandBloc] Repository returned ${brands.length} brands');
      
      if (brands.isEmpty) {
        print('🟡 [BrandBloc] No brands found, emitting BrandEmpty');
        emit(const BrandEmpty());
        return;
      }
      print('✅ [BrandBloc] Emitting BrandLoaded with ${brands.length} brands');
      emit(BrandLoaded(brands));
    } on ApiException catch (error) {
      print('❌ [BrandBloc] ApiException caught: ${error.message}');
      print('❌ [BrandBloc] Status code: ${error.statusCode}');
      emit(BrandError(error.message));
    } catch (e, stackTrace) {
      print('❌ [BrandBloc] Unexpected error: $e');
      print('❌ [BrandBloc] Stack trace: $stackTrace');
      emit(const BrandError('Unable to load brands.'));
    }
  }
}

