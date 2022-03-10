An extension to the bloc state management library to define state machines that support state's data using a nice declarative API.

## Overview

`state_machine_bloc` export a `StateMachine` class, a lightweight wrapper around `Bloc` class designed to declare state machines using a nice builder API.
`StateMachine` _is_ a `Bloc`, meaning that you can use it in the same way as a regular bloc and it's compatible with the rest of the ecosystem.

`state_machine_bloc` supports:

* [X] Storing data in states
* [X] Asynchronous state transitions
* [X] Applying guard conditions to transitions
* [X] state's onEnter/onChange/onExit side effect
* [X] Nested states without depth limit

### Usage

`StateMachine` has a narrow and user-friendly API.

See the example and test folders for additional examples.

Example of creating a StateMachine with two states:

```dart
// Base class for events handled by StateMachine
class Event {}
// Base class for StateMachine's State
class State {}

class Start extends Event {}
class Stop extends Event {}

class Idle extends State {}
class Run extends State {}

class MyStateMachine extends StateMachine<Event, State> {
    MyStateMachine() : super(Idle()) {
        define<Idle>((b) => b
            ..on<Start>(
                (Start event, Idle state) => Run(),
            ));
        define<Run>((b) => b
            ..on<Stop>(
                (Stop event, Run state) => Idle(),
            ));
    }
}
```
Use `StateMachine` like a regular bloc:

```dart
Future<void> main() async {
  /// Create a `MyStateMachine` instance.
  final stateMachine = MyStateMachine();

  /// Access the state of the `bloc` via `state`.
  print(stateMachine.state); // Idle object

  /// Interact with the `stateMachine` to trigger `state` changes.
  stateMachine.add(Start());

  /// Wait for next iteration of the event-loop
  /// to ensure event has been processed.
  await Future.delayed(Duration.zero);

  /// Access the new `state`.
  print(stateMachine.state); // Run object

  /// Close the `stateMachine` when it is no longer needed.
  await stateMachine.close();
}
```

with `flutter_bloc`:
```dart
BlocProvider(
    create: (_) => MyStateMachine(),
    child: ...,
);
```

### Defining states and events

`StateMachine` expose `define<State>` method that should be used to define each state machine's possible state and its transitions to other states. You can also register side effects to react to state lifecycle events.

Just like `Bloc`, a state machine defined as `StateMachine<Event, State>` should have each of its defined states a sub-type of `State` and each of its defined events a sub-type of `Event`.

You can call `define` as many times you want, but each defined state should have a unique type. Another rule is that the state machine should never be in a state that it has not been defined. If this happens, `StateMachine` will throw an `InvalidState` error.

**`define` should only be used inside `StateMachine`'s constructor**
**Don't use `on<Event>` inside `StateMachine`. `StateMachine` takes care of calling `on<Event>` under the hood for you.**

```dart
 define<State>((b) => b
    ..onEnter((State state) { /* Side effect */ }) 
    ..on<Event>((Event event, State state) => NextState()) //transition to NextState
```

### Transitions
```dart
//inside MyStateMachine's constructor
define<State>((b) => b
    ..on<ButtonPressed>( //create new transition
        (ButtonPressed event, State state) => state.enabled ? NextState() : null, //return null to prevent transition
    )
    ..on<DataReceived>( //transition are evaluated sequentially
        (DataReceived event, State state) => OtherState(),
    )
    ..on<DataReceived>( //you can have as many transitions you want, even of the same Event type
        (DataReceived event, State state) => OtherState(),
    )
    ..on<OtherEvent>( // transitions can be async
        (OtherEvent event, State state) async => await nextState(),
    )

define<NextState>();
define<OtherState>();
```
Transitions are evaluated sequentially. Transitions are evaluated in the same order that they are defined. If a transition is `async`, it will be awaited before evaluating the next one.

A transition could return a new state or null to indicate that the transition is refused. If a state is returned, state machine transit to this new state. If null is returned, the next transition is evaluated.
If all transitions return null, the current state remains unchanged and no side effects are triggered.

**If a new state is returned from a transition where `newState == state`, the new state will be ignored**. If you're using state that contain data, make sure you've implemented `==` operator. You could use `freezed` or `equatable` package for this purpose. See example folder.

### Side Effects
```dart
define<State>((b) => b
    ..onEnter((State state) { /* called when entering State */ })
    ..onChange((State current, State next) { /* called when State data changed */ })
    ..onExit((State state) { /* called when exiting State */ })
```

**onEnter** is called when State Machine enters a state. If `State` is the initial `StateMachine`'s state, onEnter is called at initialization.
**onChange** is called when a state transit to itself. onChange **is not** called if `state == nextState` or when the state machine enter the state for the first time.
**onExit** is called before State Machine's exit a state.

#### Async side effect

You can give async function as parameter for side effects, but remember they will **not** be awaited.
```dart
define<State>((b) => b
    ..onEnter((State state) async { /* not awaited */ })
```

### Nested State

Nested states are useful to define transitions or side effects that are common to a group of states.

```dart
define<Off>()
    ..on<TurnOn>((Off state) => Green())
);

define<On>((b) => b
    ..on<ShutDown>((On state) => Off())
    ..define<Red>((b) => b
        ..onEnter(_wait(30))
        ..on<Next>(_transitToGreen))
    ..define<Orange>((b) => b
        ..onEnter(_wait(5))
        ..on<Next>(_transitToRed))
    ..define<Green>((b) => b
        ..onEnter(_wait(25))
        ..on<Next>(_transitToOrange))
);
```

Nested states are created by calling `define<State>` method on another state's builder. There is no limit to the depth of state nesting. Nested states have the same capabilities as other states. They have access to both transitions and side effects. However, there are few limitations that you should keep in mind:
- Nested states should always be a sub-type of their parent state's type
- State machine can ony be in state that has no child. You should never transit to parent state directly. Transit to one of it's child state instead.

#### Transition evaluation order
Parent's transitions and side effects are evaluated first. If parent enters transition, child transitions will not be evaluated.

#### Side effects
**onEnter**
- for parent state: called when entering one of its sub-state
- for child state: called each time entering the given child state

**onChange**
- for parent state: called each time a child state changes or transit to one of its other child states.
- for child state: called each time child transit to itself and `state != nextState`. 

**onExit**
- for parent state: called when `nextState` is not a sub-type of parent state.
- for child state: called each time exiting the given child state

## Additional ressources

* [You are managing state? Think twice.](https://krasimirtsonev.com/blog/article/managing-state-in-javascript-with-state-machines-stent)
* [The rise of state machine](https://www.smashingmagazine.com/2018/01/rise-state-machines/)
* [Robust React User Interfaces with Finite State Machines](https://css-tricks.com/robust-react-user-interfaces-with-finite-state-machines/)
