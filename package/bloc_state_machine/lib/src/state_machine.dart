import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'state_definition.dart';
part 'state_definition_builder.dart';

abstract class StateMachine<Event, State> extends BlocBase<State>
    implements BlocEventSink<Event> {
  StateMachine(State initial) : super(initial) {
    _bindInternalStateStream();
    _bindEventsToStates();
    _stateMachineController.add(initial);
  }

  // final _blocObserver = BlocOverrides.current?.blocObserver;
  final _stateMachineController = StreamController<State>();
  final _stateDefinitions = <Type, _StateDefinition>{};
  final _eventController = StreamController<Event>();
  late final StreamSubscription? _stateMachineSubscription;
  late final StreamSubscription? _eventSubscription;

  @override
  void add(Event event) {
    // TODO: CHECK IF HANLDER/STATE EXIST
    try {
      onEvent(event);
      _eventController.add(event);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  void define<DefinedState extends State>([
    StateDefinitionBuilder<Event, State, DefinedState> Function(
      StateDefinitionBuilder<Event, State, DefinedState>,
    )?
        definitionBuilder,
  ]) {
    // TODO: CHECK IF HANLDER/STATE EXIST
    _stateDefinitions.putIfAbsent(DefinedState, () {
      if (definitionBuilder != null) {
        return definitionBuilder
            .call(StateDefinitionBuilder<Event, State, DefinedState>())
            ._build();
      } else {
        return _StateDefinition<Event, State, DefinedState>.empty();
      }
    });
  }

  @protected
  @mustCallSuper
  void onEvent(Event event) {
    // TODO: StateMachineObserver
    // ignore: invalid_use_of_protected_member
    // _blocObserver?.onEvent(this, event);
  }

  /// Maybe exposing emit its not a good idea ?
  /// State should be added via _stateMachineController.add(state)
  /// Otherwise it will not trigger onEnter/onExit
  @protected
  @visibleForTesting
  @override
  void emit(State state) => super.emit(state);

  void _bindEventsToStates() {
    //Todo: add transformer
    _eventSubscription = _eventController.stream.asyncMap<State?>(
      (event) async {
        return (await _currentStateDefinition.add(event, state)) as State?;
      },
    ).listen((State? maybeState) {
      if (maybeState != null) {
        _stateMachineController.add(maybeState);
      }
    });
  }

  /// Listen to [_stateMachineController] to [emit] new State
  /// and trigger onEnter, onExit callback
  /// onEnter is awaited and if it emit a new state (immediate transition),
  /// emitted state is added to [_stateMachineController]'s stream.
  /// While processing of newState and until onEnter return null,
  /// Event processing are disabled using [_eventSubscription]'s pause method
  void _bindInternalStateStream() {
    _stateMachineSubscription =
        _stateMachineController.stream.asyncMap((newState) async {
      _eventSubscription?.pause();
      _currentStateDefinition.exit(state);
      emit(newState);
      final immediateStateTransition = (await _currentStateDefinition.enter(
        newState,
      )) as State?;
      if (immediateStateTransition != null) {
        _stateMachineController.add(immediateStateTransition);
      } else {
        _eventSubscription?.resume();
      }
    }).listen(null);
  }

  // Closes the `event` and `state` `Streams`.
  // This method should be called when a [Bloc] is no longer needed.
  // Once [close] is called, `events` that are [add]ed will not be
  // processed.
  // In addition, if [close] is called while `events` are still being
  // processed, the [Bloc] will finish processing the pending `events`.
  @mustCallSuper
  @override
  Future<void> close() async {
    await _eventSubscription?.cancel();
    await _stateMachineSubscription?.cancel();
    await _eventController.close();
    await _stateMachineController.close();
    return super.close();
  }

  //TODO: error if no hanlder exist
  _StateDefinition get _currentStateDefinition =>
      _stateDefinitions[state.runtimeType]!;
}
