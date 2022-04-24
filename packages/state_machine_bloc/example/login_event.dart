part of 'simple_login_sm.dart';

class LoginEvent {
  const LoginEvent();
}

class LoginFormSubmitted extends LoginEvent {
  const LoginFormSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class LoginSucceeded extends LoginEvent {}

class LoginFailed extends LoginEvent {
  const LoginFailed(
    this.reason,
  );

  final String reason;
}
