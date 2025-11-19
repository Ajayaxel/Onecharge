import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/api_exception.dart';
import '../../data/models/login_response.dart';
import '../../data/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState>
    implements StateStreamable<LoginState> {
  LoginBloc(this._repository) : super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final AuthRepository _repository;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LoginStatus.loading,
        clearMessage: true,
      ),
    );
    try {
      final response = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(
        state.copyWith(
          status: LoginStatus.success,
          user: response.user,
          message: response.message,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          message: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}


