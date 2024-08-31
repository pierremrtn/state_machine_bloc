import 'package:state_machine_bloc/state_machine_bloc.dart';
import 'package:test/test.dart';

import 'utils.dart';

abstract class Event {}

class EventA extends Event {}

class EventB extends Event {}

abstract class State {
  const State();
}

class StateA extends State {
  const StateA();
}

class StateB extends StateA {
  const StateB();
}

class StateC extends State {
  const StateC();
}

class StateD extends State {
  const StateD();
}

class DummyStateMachine extends StateMachine<Event, State> {
  DummyStateMachine([State? initial]) : super(initial ?? const StateA()) {
    define<StateA>(
      ($) => $
        ..define<StateB>(($) => $
          ..on((EventA e, s) async {
            await Future.delayed(Duration(milliseconds: 300));
            return const StateC();
          })
          ..on((EventB e, s) {
            return const StateD();
          })),
    );
    define<StateC>();
    define<StateD>();
  }
}

void main() {
  group("event receiving tests", () {
    test("Nested transitions are awaited", () async {
      final sm = DummyStateMachine(const StateB());
      sm.add(EventA());

      await wait();

      expect(sm.state, const StateB());

      await Future.delayed(Duration(seconds: 1));

      expect(sm.state, const StateC());
    });
  });

  test("Nested transitions are evaluated sequentially", () async {
    final sm = DummyStateMachine(const StateB());
    sm.add(EventA());
    sm.add(EventB());

    await wait();

    expect(sm.state, const StateB());

    await Future.delayed(Duration(seconds: 1));

    expect(sm.state, const StateC());
  });
}
