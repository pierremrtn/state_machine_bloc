part of 'state_machine.dart';

/// A builder that let's define a state transitions
///
/// * [onEnter] let you register a [StateBuilder] that is called immediately
/// after state machine enter in [DefinedState]. If [StateBuilder] emit
/// a new state, state machine will transit to that state.
/// State machine will wait for onEnter Completion in order to evaluate
/// any event received, meaning that you are guaranteed that [onEnter]
/// transition will always be evaluated before [on] transition and [onExit]
///
/// * [on] let you register an additional event handler for [DefinedState].
/// You can have multiple [on] transition of the same [Event] type.
/// [on] transitions are evaluated sequentially, meaning if two or more
/// [on] transitions could transit to a new [State] only the first declared one
/// will be evaluated an therefore emit a new state.
///
/// * [onExit] let you register a [SideEffect] callback that will be called when
/// the state machine leave [DefinedState]
class StateDefinitionBuilder<Event, State, DefinedState extends State> {
  final List<_StateEventHandler> _handlers = [];
  SideEffect<DefinedState>? _onEnter;
  SideEffect<DefinedState>? _onExit;

  /// Let you register a [StateBuilder] that is called immediately
  /// after state machine enter in [DefinedState].
  ///
  /// If [StateBuilder] emit
  /// a new state, state machine will transit to that state.
  /// State machine will wait for onEnter Completion in order to evaluate
  /// any event received, meaning that you are guaranteed that [onEnter]
  /// transition will always be evaluated before [on] transition and [onExit]
  void onEnter(SideEffect<DefinedState> sideEffect) {
    assert(() {
      if (_onEnter != null) {
        throw StateError(
          'onEnter was called multiple times.'
          'There should only be a single onEnter handler per state.',
        );
      }
      return true;
    }());
    _onEnter = sideEffect;
  }

  /// Let you register a [SideEffect] callback that will be called when
  /// the state machine leave [DefinedState].
  void onExit(SideEffect<DefinedState> sideEffect) {
    assert(() {
      if (_onExit != null) {
        throw StateError(
          'onExit was called multiple times.'
          'There should only be a single onExit handler per state.',
        );
      }
      return true;
    }());
    _onExit = sideEffect;
  }

  /// [on] let you register an additional event handler for [DefinedState].
  ///
  /// You can have multiple [on] transition of the same [Event] type.
  /// [on] transitions are evaluated sequentially, meaning if two or more
  /// [on] transitions could transit to a new [State] only the first declared one
  /// will be evaluated an therefore emit a new state.
  void on<DefinedEvent extends Event>(
          EventTransition<DefinedEvent, State, DefinedState> builder
          //    {
          //   EventTransformer<DefinedEvent>? transformer,
          // }
          ) =>
      _handlers.add(
        _StateEventHandler<Event, State, DefinedEvent, DefinedState>(
          builder: builder,
          isType: (dynamic e) => e is DefinedEvent,
          type: DefinedEvent,
        ),
      );

  _StateDefinition<Event, State, DefinedState> _build() => _StateDefinition(
        _handlers,
        onEnter: _onEnter,
        onExit: _onExit,
      );
}
