part of 'state_machine.dart';

/// Signature of a function that may or may not emit a new state
/// base on it's current state an an external event
typedef EventTransition<Event, SuperState, CurrentState extends SuperState>
    = FutureOr<SuperState?> Function(Event, CurrentState);

/// Signature of a callback function called by the state machine
/// in various contexts that hasn't the ability to emit new state
typedef SideEffect<CurrentState> = void Function(CurrentState);

/// An event handler for a given [DefinedState]
/// created using on<Event>() api
class _StateEventHandler<SuperEvent, SuperState,
    DefinedEvent extends SuperEvent, DefinedState extends SuperState> {
  const _StateEventHandler({
    required this.isType,
    required this.type,
    required this.builder,
    // this.transformer,
  });
  final bool Function(dynamic value) isType;
  final Type type;

  final EventTransition<DefinedEvent, SuperState, DefinedState> builder;
  // final EventTransformer<SuperEvent>? transformer;

  FutureOr<SuperState?> handle(SuperEvent e, SuperState s) async =>
      builder(e as DefinedEvent, s as DefinedState);
}

/// Definition of a state
/// This class is intended to be constructed using
/// [StateDefinitionBuilder]
class _StateDefinition<Event, SuperState, DefinedState extends SuperState> {
  const _StateDefinition(
    this._handlers, {
    this.onEnter,
    this.onChange,
    this.onExit,
  });

  const _StateDefinition.empty()
      : _handlers = const [],
        onEnter = null,
        onChange = null,
        onExit = null;

  /// Called whenever entering state.
  final SideEffect<DefinedState>? onEnter;

  /// Called whenever current state's data changed with the given updated state.
  final SideEffect<DefinedState>? onChange;

  /// Called whenever exiting state.
  final SideEffect<DefinedState>? onExit;
  final List<_StateEventHandler> _handlers;

  void enter(DefinedState state) => onEnter?.call(state);
  void change(DefinedState state) => onChange?.call(state);
  void exit(DefinedState state) => onExit?.call(state);

  FutureOr<SuperState?> add(
    Event event,
    SuperState state,
  ) async {
    final stateHandlers = _handlers.where(
      (handler) => handler.isType(event),
    );
    for (final handler in stateHandlers) {
      final nextState = (await handler.handle(event, state)) as SuperState?;
      if (nextState != null) return nextState;
    }
    return null;
  }
}
