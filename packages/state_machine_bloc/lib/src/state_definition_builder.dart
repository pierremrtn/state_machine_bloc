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
  final List<Type> _definedStates = [];
  final List<_StateEventHandler> _handlers = [];
  final List<_StateDefinition> _nestedStateDefinitions = [];
  SideEffect<DefinedState>? _onEnter;
  SideEffect<DefinedState>? _onExit;
  OnChangeSideEffect<DefinedState>? _onChange;

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
          'There should only be a single onEnter side effect registered per state.',
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
          'There should only be a single onExit side effect registered per state.',
        );
      }
      return true;
    }());
    _onExit = sideEffect;
  }

  /// Let you register a [OnChangeSideEffect] callback that will be called when
  /// the state machine transit to a nextState where currentState == nextState
  /// onChange is also called when the state machine transit from on of
  /// [DefinedState]'s sub-state to another sub state of [DefinedState].
  void onChange(OnChangeSideEffect<DefinedState> sideEffect) {
    assert(() {
      if (_onChange != null) {
        throw StateError(
          'onChange was called multiple times.'
          'There should only be a single side effect onChange effect per state.',
        );
      }
      return true;
    }());
    _onChange = sideEffect;
  }

  /// [on] let you register an additional event handler for [DefinedState].
  ///
  /// You can have multiple [on] transition of the same [Event] type.
  /// [on] transitions are evaluated sequentially, meaning if two or more
  /// [on] transitions could transit to a new [State] only the first declared one
  /// will be evaluated an therefore emit a new state.
  void on<DefinedEvent extends Event>(
    EventTransition<DefinedEvent, State, DefinedState> builder,
  ) =>
      _handlers.add(
        _StateEventHandler<Event, State, DefinedEvent, DefinedState>(
          builder: builder,
          isType: (dynamic e) => e is DefinedEvent,
          type: DefinedEvent,
        ),
      );

  void define<NestedState extends DefinedState>([
    StateDefinitionBuilder<Event, State, NestedState> Function(
            StateDefinitionBuilder<Event, State, NestedState>)?
        builder,
  ]) {
    late _StateDefinition definition;
    if (builder != null) {
      definition = builder
          .call(StateDefinitionBuilder<Event, State, NestedState>())
          ._build();
    } else {
      definition = _StateDefinition<Event, State, NestedState>.empty();
    }

    assert(() {
      if (_definedStates.contains(NestedState)) {
        throw "$NestedState defined multiple times. State should only be defined once.";
      }
      _definedStates.add(NestedState);
      return true;
    }());

    _nestedStateDefinitions.add(definition);
  }

  _StateDefinition<Event, State, DefinedState> _build() => _StateDefinition(
        handlers: _handlers,
        nestedStatesDefinitions:
            _nestedStateDefinitions.isNotEmpty ? _nestedStateDefinitions : null,
        onEnter: _onEnter,
        onExit: _onExit,
        onChange: _onChange,
      );
}
