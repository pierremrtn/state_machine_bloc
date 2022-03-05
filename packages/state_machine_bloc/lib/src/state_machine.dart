import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'state_definition.dart';
part 'state_definition_builder.dart';

typedef TransitionFunction<Event, State> = Stream<Transition<Event, State>>
    Function(Event);

abstract class StateMachine<Event, State> extends Bloc<Event, State> {
  StateMachine(State initial) : super(initial) {
    on<Event>(
      (event, emit) {
        return emit.onEach(
          mapEventToState(event),
          onData: (State? newState) {
            if (newState != null) emit(newState);
          },
        );
      },
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

  @protected
  @visibleForTesting
  @override
  void emit(State newState) {
    _stateDefinitions[state.runtimeType]?.exit(state);
    super.emit(newState);
    _stateDefinitions[newState.runtimeType]?.enter(newState);
  }

  Stream<State> mapEventToState(Event event) async* {
    final definition = _stateDefinitions[state.runtimeType];
    if (definition == null) return;

    final newState = (await definition.add(event, state)) as State?;
    if (newState == null) return;
    yield newState;
  }
}
