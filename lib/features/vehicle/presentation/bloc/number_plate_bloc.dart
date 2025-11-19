import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/models/number_plate_response.dart';
import '../../data/repositories/number_plate_repository.dart';

part 'number_plate_event.dart';
part 'number_plate_state.dart';

class NumberPlateBloc extends Bloc<NumberPlateEvent, NumberPlateState> {
  NumberPlateBloc(this._repository) : super(const NumberPlateState()) {
    on<NumberPlateSubmitted>(_onNumberPlateSubmitted);
    on<NumberPlateReset>(_onNumberPlateReset);
  }

  final NumberPlateRepository _repository;

  Future<void> _onNumberPlateSubmitted(
    NumberPlateSubmitted event,
    Emitter<NumberPlateState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NumberPlateStatus.loading,
        message: null,
        statusCode: null,
        data: null,
      ),
    );

    try {
      final response = await _repository.saveNumberPlate(
        plateNumber: event.plateNumber,
      );

      emit(
        state.copyWith(
          status: NumberPlateStatus.success,
          message: response.message,
          data: response.data,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: NumberPlateStatus.failure,
          message: error.message,
          statusCode: error.statusCode,
          data: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: NumberPlateStatus.failure,
          message: 'Unable to save number plate.',
          data: null,
        ),
      );
    }
  }

  void _onNumberPlateReset(
    NumberPlateReset event,
    Emitter<NumberPlateState> emit,
  ) {
    emit(const NumberPlateState());
  }
}
