import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';

part 'state_definition.dart';
part 'state_definition_builder.dart';

typedef TransitionFunction<Event, State> = Stream<Transition<Event, State>>
    Function(Event);

abstract class StateMachine<Event, State> extends Bloc<Event, State> {
  StateMachine(State initial) : super(initial) {
    super.on<Event>(
      _mapEventToState,
      transformer: sequential(),
    );
  }

  final _stateDefinitions = <Type, _StateDefinition>{};

  void define<DefinedState extends State>([
    StateDefinitionBuilder<Event, State, DefinedState> Function(
      StateDefinitionBuilder<Event, State, DefinedState>,
    )?
        definitionBuilder,
  ]) {
    final definition = _stateDefinitions.putIfAbsent(DefinedState, () {
      if (definitionBuilder != null) {
        return definitionBuilder
            .call(StateDefinitionBuilder<Event, State, DefinedState>())
            ._build();
      } else {
        return _StateDefinition<Event, State, DefinedState>.empty();
      }
    });
    if (state.runtimeType is DefinedState) {
      definition.enter(state);
    }
  }

  // [on] function should not be used inside [StateMachine].
  // Use [define] instead.
  @protected
  @override
  void on<E extends Event>(
    EventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) {
    throw "You should use StateMachine.define instead";
  }

  Future<void> _mapEventToState(Event event, Emitter emit) async {
    final definition = _stateDefinitions[state.runtimeType];
    if (definition == null) return;

    final nextState = (await definition.add(event, state)) as State?;
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
    final currentType = change.nextState.runtimeType;
    final nextType = change.nextState.runtimeType;
    if (currentType == nextType) {
      _stateDefinitions[currentType]?.change(change.nextState);
    } else {
      _stateDefinitions[currentType]?.exit(change.currentState);
      _stateDefinitions[currentType]?.enter(change.nextState);
    }
  }
}
