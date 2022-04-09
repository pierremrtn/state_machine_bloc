An extension to the bloc state management library to easily create bloc that behave like traditional state machine.

## Overview

`state_machine_bloc` export a `StateMachine` class, a lightweight wrapper around `Bloc` class that expose convenient methods to describe a state machine.
`StateMachine` _is_ a `Bloc`, meaning that you can use it in the same way as a regular bloc and it's compatible with the rest of the ecosystem.

`StateMachine` automatically route and filter events according its current state for you so you can focus on building app logic. The package use a flexible builder API to conveniently describe simples to complex state machines.

`state_machine_bloc` enable you to:
* ✅ Easily define state machine states and their transitions
* ✅ Store different data for each states
* ✅ Register callbacks to state's lifecycle events
* ✅ Apply guard conditions on transitions
* ✅ Nest states without depth limit

### Usage

`StateMachine` expose a new method, `define<State>`, similar to `Bloc`'s `on<Event>`. `define<State>` is used to define one of the state machine's possible states. Its takes a builder function as parameter that lets you register events handlers and side effect for the defined state.

> 🚨 You should **NEVER** use `on<Event>` method inside a StateMachine

`define`'s state definition builder function takes a `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` expose methods to register event handlers and side effects.

**Event handlers** react to an incoming event and emit or not the next state of the state machine. If they do, State machine transit to this new state. It's called a transition.

**Side effects** are callback function called depending on state lifecycle. You have access to three side effects: `onEnter`, `onExit`and `onChange`.

Example of a login-in form state machine. States names and declarations has been voluntary simplified for demonstration purpose.You still need to implement `operator==` like you do with `Bloc`, using `equatable` or `freezed`.

```dart
import 'package:state_machine_bloc/state_machine_bloc.dart';

// Base classes for state machine's events and states
class State {}
class Event {}

// State machine's states
class WaitingFormSubmission extends State {}
class TryLoggingIn extends State {
    TryLoggingIn({required this.email, required this.password});
    final String email;
    final String password;
}
class Success extends State {}
class Error extends State {}

// State machine's events
class FormSubmitted extends Event {
    FormSubmitted({required this.email, required this.password});
    final String email;
    final String password;
}
class LoginSucceeded extends Event {}
class LoginFailed extends Event {
    LoginFailed(this.reason);
    final String reason;
}

// State machine's definition
class LoginStateMachine extends StateMachine<Event, State> {
    LoginStateMachine({
        required this.userRepository,
    }) : super(WaitingFormSubmission()) {

        define<WaitingFormSubmission>(($) => $
            ..on<FormSubmitted>(_transitToTryLoggingIn));

        define<TryLoggingIn>((b) => b
            ..onEnter(_login)
            ..on<LoginSucceeded>(_transitToSuccess)
            ..on<LoginFailed>(_transitToError));

        define<LoginSuccess>();
        define<LoginError>();
    }

    final UserRepository userRepository;

    TryLoggingIn _transitToTryLoggingIn(
        FormSubmitted event, state,
    ) => TryLoggingIn(
        email: event.email,
        password: event.password,
    );

    LoginSucceed _transitToSuccess(event, state) => LoginSucceed();

    LoginError _transitToError(event, state) => LoginError();

    Future<void> _login(TryLoggingIn state) async {
        try {
            await userRepository.login(
                email: state.email,
                password: state.password,
            );
            add(LoginSucceeded());
        } catch (e) {
            add(LoginFailed(e.toString()));
        }
    }
}
```

`StateMachine` **is** a `Bloc`, so you could use it in the same way as `Bloc`:

```dart
BlocProvider(
    create: (_) => MyStateMachine(),
    child: ...,
);

...

BlocBuilder<MyStateMachine, MyStateMachineState>(  
    builder: ...,
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
