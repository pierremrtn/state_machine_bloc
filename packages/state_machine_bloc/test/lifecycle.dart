import 'package:state_machine_bloc/state_machine_bloc.dart';
import 'package:test/test.dart';

import 'utils.dart';

abstract class Event {}

class EventA extends Event {}

class TriggerStateOnChange extends Event {}

abstract class State {
  @override
  bool operator ==(Object value) => false;

  @override
  int get hashCode => 0;
}

class StateA extends State {}

class StateB extends State {}

class DummyStateMachine extends StateMachine<Event, State> {
  DummyStateMachine({
    State? initialState,
  }) : super(initialState ?? StateA()) {
    define<StateA>(
      ($) => $
        ..onEnter((_) => onEnterCalls.add("StateA"))
        ..onExit((_) => onExitCalls.add("StateA"))
        ..onChange((_, __) => onChangeCalls.add("StateA"))
        ..on<EventA>((_, __) => StateB()),
    );

    define<StateB>(
      ($) => $
        ..onEnter((_) => onEnterCalls.add("StateB"))
        ..onExit((_) => onExitCalls.add("StateB"))
        ..onChange((_, __) => onChangeCalls.add("StateB"))
        ..on<TriggerStateOnChange>((_, __) => StateB()),
    );
  }

  List<String> onEnterCalls = [];
  List<String> onExitCalls = [];
  List<String> onChangeCalls = [];
}

void main(List<String> args) {
  group("Lifecycle", () {
    test("Initial state's onEnter is called at initialization", () {
      final sm = DummyStateMachine();
      expect(sm.onEnterCalls, ["StateA"]);
    });

    test("onEnter is called when entering new state", () async {
      final sm = DummyStateMachine();
      sm.add(EventA());

      await wait();

      expect(sm.onEnterCalls, ["StateA", "StateB"]);
    });

    test("onExit is called when exiting a state", () async {
      final sm = DummyStateMachine();
      sm.add(EventA());

      await wait();

      expect(sm.onExitCalls, ["StateA"]);
    });

    test("onChange is called when transiting to same state", () async {
      final sm = DummyStateMachine(initialState: StateB());
      sm.add(TriggerStateOnChange());

      await wait();

      expect(sm.onChangeCalls, ["StateB"]);
    });

    test("onChange is not called when transiting to an other state", () async {
      final sm = DummyStateMachine();
      sm.add(EventA());

      await wait();

      expect(sm.onChangeCalls, []);
    });
  });
}
