part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.message,
  });

  final LoginStatus status;
  final UserModel? user;
  final String? message;

  LoginState copyWith({
    LoginStatus? status,
    UserModel? user,
    String? message,
    bool clearMessage = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  bool get isLoading => status == LoginStatus.loading;

  @override
  List<Object?> get props => [status, user, message];
}
