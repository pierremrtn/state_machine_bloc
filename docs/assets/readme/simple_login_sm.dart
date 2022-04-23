import 'package:state_machine_bloc/state_machine_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginStateMachine extends StateMachine<LoginEvent, LoginState> {
  LoginStateMachine({
    required this.userRepository,
  }) : super(WaitingFormSubmission()) {
    define<WaitingFormSubmission>(
        ($) => $..on<LoginFormSubmitted>(_toTryLoggingIn));

    define<TryLoggingIn>(($) => $
      ..onEnter(_login)
      ..on<LoginSucceeded>(_toSuccess)
      ..on<LoginFailed>(_toError));

    define<LoginSuccess>();
    define<LoginError>();
  }

  final UserRepository userRepository;

  TryLoggingIn _toTryLoggingIn(FormSubmitted event, state) =>
      TryLoggingIn(email: event.email, password: event.password);

  LoginSucceed _toSuccess(e, s) => LoginSucceed();

  LoginError _toError(LoginFailed event, state) => LoginError(event.error);

  /// Use state's data to try login-in using the API
  Future<void> _login(TryLoggingIn state) async {
    try {
      await userRepository.login(
        email: state.email,
        password: state.password,
      );
      add(LoginSucceeded());
    } catch (e) {
      add(LoginFailed(e.toString()));
    }
  }
}
