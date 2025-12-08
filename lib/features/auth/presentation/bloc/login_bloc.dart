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
      // Check if this is a 403 error with email verification requirement
      final messageLower = error.message.toLowerCase();
      final isEmailVerificationError = error.statusCode == 403 &&
          (messageLower.contains('verify your email') ||
           messageLower.contains('verify') && messageLower.contains('email') ||
           messageLower.contains('otp') ||
           messageLower.contains('verification code') ||
           messageLower.contains('email verification'));
      
      if (isEmailVerificationError) {
        // Use email from error response, or fallback to email from login event
        final email = error.email ?? event.email;
        // Navigate to OTP verification screen
        emit(
          state.copyWith(
            status: LoginStatus.requiresVerification,
            message: error.message,
            email: email,
            requiresVerification: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            message: error.message,
          ),
        );
      }
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


