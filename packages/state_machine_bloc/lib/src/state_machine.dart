import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';

part 'state_definition.dart';
part 'state_definition_builder.dart';

/// {@template state_machine}
/// A Bloc that provides facilities methods to create state machines
///
/// The state machine uses `Bloc`'s `on<Event>` method under the hood with a
/// custom event dispatcher that will in turn call your methods and callbacks.
///
/// State machine's states should be defined with the
/// `StateMachine`'s `define<State>` methods inside the constructor. You should
/// never try to transit to a state that hasn't been explicitly defined.
/// If the state machine detects a transition to an undefined state,
/// it will throw an error.
///
/// Each state has its own set of event handlers and side effects callbacks:
/// * **Event handlers** react to an incoming event and can emit the next
///  machine's state. We call this a _transition_.
/// * **Side effects** are callback functions called depending on state
///  lifecycle. You have access to three different side effects: `onEnter`, `onExit`, and `onChange`.
///
/// When an event is received, the state machine will first search
/// for the actual state definition. Each current state's event handler
/// that matches the received event type will be evaluated.
/// If multiple events handlers match the event type, they will be evaluated
/// in their **definition order**. As soon as an event handler returns
/// a non-null state (we call this _entering a transition_), the state
/// machine stops evaluating events handlers and transit to the new
/// state immediately.
///
/// ```dart
/// class MyStateMachine extends StateMachine<Event, State> {
/// MyStateMachine() : super(InitialState()) {
///    define<InitialState>(($) => $
///      ..onEnter((InitialState state) { /** ... **/ })
///      ..onChange((InitialState state, InitialState nextState) { /** ... **/ })
///      ..onExit((InitialState state) { /** ... **/ })
///      ..on<SomeEvent>((SomeEvent event, InitialState state) => OtherState())
///    );
///    define<OtherState>();
///   }
/// }
/// ```
///
/// See also:
///
/// * [Bloc] class for more information about general blocs behavior
/// {@endtemplate state_machine}
abstract class StateMachine<Event, State> extends Bloc<Event, State> {
  /// {@macro state_machine}
  StateMachine(
    State initial, {

    /// Used to change how state machine process incoming events. The default event transformer is [droppable] by default,
    /// meaning it process only one event and ignore (drop) any new events until the next event-loop iteration.
    EventTransformer<Event>? transformer,
  }) : super(initial) {
    super.on<Event>(_mapEventToState, transformer: transformer ?? droppable());
  }

  final List<Type> _definedStates = [];
  final List<_StateDefinition> _stateDefinitions = [];

  /// Register [DefinedState] as one of the allowed machine's states.
  ///
  /// The define method should be called once for allowed state
  /// **inside the class constructor**. Defined states should
  /// always be sub-classes of the [State] class.
  ///
  /// The define method takes an optional [definitionBuilder] function as
  /// parameter that give the opportunity to register events handler and
  /// transitions for the [DefinedState] thanks to a [StateDefinitionBuilder]
  /// passed as parameter to the builder function.
  /// The [StateDefinitionBuilder] provides all necessary methods to registers
  /// event handlers, side effects and nested states. The [definitionBuilder]
  /// should call needed [StateDefinitionBuilder]'s object methods to describe
  /// the [DefinedState] and then return it.
  ///
  /// ```dart
  /// class MyStateMachine extends StateMachine<Event, State> {
  /// MyStateMachine() : super(InitialState()) {
  ///    define<InitialState>(($) => $
  ///      ..onEnter((InitialState state) { /** ... **/ })
  ///      ..onChange((InitialState state, InitialState nextState) { /** ... **/ })
  ///      ..onExit((InitialState state) { /** ... **/ })
  ///      ..on<SomeEvent>((SomeEvent event, InitialState state) => OtherState())
  ///    );
  ///    define<OtherState>();
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [StateDefinitionBuilder] for more information about defining states.
  void define<DefinedState extends State>([
    StateDefinitionBuilder<Event, State, DefinedState> Function(
      StateDefinitionBuilder<Event, State, DefinedState>,
    )?
        definitionBuilder,
  ]) {
    late final _StateDefinition definition;
    if (definitionBuilder != null) {
      definition = definitionBuilder
          .call(StateDefinitionBuilder<Event, State, DefinedState>())
          ._build();
    } else {
      definition = _StateDefinition<Event, State, DefinedState>.empty();
    }

    assert(() {
      if (_definedStates.contains(DefinedState)) {
        throw "$DefinedState defined multiple times. State should only be defined once.";
      }
      _definedStates.add(DefinedState);
      return true;
    }());

    _stateDefinitions.add(definition);

    if (state is DefinedState) {
      definition.onEnter(state);
    }
  }

  /// [on] function should never be used inside [StateMachine].
  /// Use [define] method instead.
  @nonVirtual
  @protected
  @override
  void on<E extends Event>(
    EventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) {
    throw "Invalid use of StateMachine.on(). You should use StateMachine.define() instead.";
  }

  void _mapEventToState(Event event, Emitter emit) {
    final definition = _stateDefinitions.firstWhere((def) => def.isType(state));

    final nextState = definition.add(event, state) as State?;
    if (nextState != null) {
      emit(nextState);
    }
  }

  /// Called whenever a [change] occurs with the given [change].
  /// A [change] occurs when a new `state` is emitted.
  /// [onChange] is called before the `state` of the `cubit` is updated.
  /// [onChange] is a great spot to add logging/analytics for a specific `cubit`.
  ///
  /// **Note: `super.onChange` should always be called first.**
  /// ```dart
  /// @override
  /// void onChange(Change change) {
  ///   // Always call super.onChange with the current change
  ///   super.onChange(change);
  ///
  ///   // Custom onChange logic goes here
  /// }
  /// ```
  ///
  /// See also:
  ///
  /// * [BlocObserver] for observing [Cubit] behavior globally.
  @protected
  @mustCallSuper
  @override
  void onChange(Change<State> change) {
    super.onChange(change);
    final currentDefinition = _definition(change.currentState);
    final nextDefinition = _definition(change.nextState);
    if (currentDefinition == nextDefinition) {
      currentDefinition.onChange(change.currentState, change.nextState);
    } else {
      currentDefinition.onExit(change.currentState);
      nextDefinition.onEnter(change.nextState);
    }
  }

  _StateDefinition _definition(State state) =>
      _stateDefinitions.firstWhere((def) => def.isType(state));
}
