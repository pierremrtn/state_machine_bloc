part of 'simple_login_sm.dart';

class LoginState {
  const LoginState();
}

class WaitingFormSubmission extends LoginState {}

class TryLoggingIn extends LoginState {
  const TryLoggingIn({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class LoginSuccess extends LoginState {}

class LoginError extends LoginState {
  const LoginError(
    this.error,
  );

  final String error;
}
