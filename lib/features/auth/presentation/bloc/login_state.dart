part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure, requiresVerification }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.message,
    this.email,
    this.requiresVerification = false,
  });

  final LoginStatus status;
  final UserModel? user;
  final String? message;
  final String? email;
  final bool requiresVerification;

  LoginState copyWith({
    LoginStatus? status,
    UserModel? user,
    String? message,
    String? email,
    bool? requiresVerification,
    bool clearMessage = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: clearMessage ? null : (message ?? this.message),
      email: email ?? this.email,
      requiresVerification: requiresVerification ?? this.requiresVerification,
    );
  }

  bool get isLoading => status == LoginStatus.loading;

  @override
  List<Object?> get props => [status, user, message, email, requiresVerification];
}
