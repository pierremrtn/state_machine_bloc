<p align="center">
<img src="https://raw.githubusercontent.com/Pierre2tm/state_machine_bloc/master/docs/assets/state_machine_bloc_logo_full.png" height="100" alt="State machine Bloc" />
</p>

<p align="center">
<a href="https://github.com/Pierre2tm/state_machine_bloc"><img src="https://img.shields.io/github/stars/Pierre2tm/state_machine_bloc.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
<a href="https://github.com/tenhobi/effective_dart"><img src="https://img.shields.io/badge/style-effective_dart-40c4ff.svg" alt="style: effective dart"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/felangel/bloc"><img src="https://tinyurl.com/bloc-library" alt="Bloc Library"></a>
</p>
<p align="center">⚠️ state_machine_bloc is not an official bloc package ⚠️</p>

`state_machine_bloc` exports a `StateMachine`, a lightweight class that inherits from `Bloc` and exposes convenient methods to describe state machines.
`StateMachine` **is** a `Bloc`, meaning that you can use it in the same way as a regular bloc and it's compatible with the rest of the ecosystem.

The package uses a flexible declarative API to conveniently describe simple to complex state machines. `StateMachine` route and filter events for you so you can focus on building app logic.

**`state_machine_bloc` enables you to:**
* ✅ Easily define state machine's states and their transitions
* ✅ Store different data for each state
* ✅ React to states lifecycle events
* ✅ Apply guard conditions on transitions
* ✅ Nest states without depth limit

# Index
* <a href="#How-to-use">How to use</a>
* <a href="#StateMachine-vs-Bloc">StateMachine vs Bloc</a>
* <a href="#when-to-use-statemachine">When to use StateMachine?</a>
* <a href="#Documentation">Documentation</a>
  * <a href="#The-state-machine">The state machine</a>
    * <a href="#Events-processing-order">Events processing order</a>
    * <a href="#Transitions-evaluation">Transitions evaluation</a>
  * <a href="#Defining-states">Defining states</a>
    * <a href="#Event-handlers">Event handlers</a>
    * <a href="#Side-effects">Side effects</a>
  * <a href="#Nesting-states">Nesting states</a>
    * <a href="#Nested-states-event-handlers">Nested states event handlers</a>
    * <a href="#Nested-state-side-effects">Nested state side effects</a>
* <a href="#Examples">Examples</a>
* <a href="#Issues-and-feature-requests">Issues and feature requests</a>
* <a href="#Additional-resources">Additional resources</a>

# How to use
`StateMachine` exposes a `define<State>` method, similar to `Bloc`'s `on<Event>`, used to define one of the state machine's possible states. It takes a builder function as parameter that lets you register events handlers and side effects for the defined state.

> 🚨 You should **NEVER** use `on<Event>` method inside a StateMachine.

`define`'s state definition builder function takes a `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` exposes methods to register event handlers and side effects.

**Event handlers** react to an incoming event and can emit the next machine's state. We call this a _transition_.

**Side effects** are callback functions called depending on state lifecycle. You have access to three different side effects: `onEnter`, `onExit`, and `onChange`.

**Example of a login-in form state machine:**
```dart
import 'package:state_machine_bloc/state_machine_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginStateMachine extends StateMachine<LoginEvent, LoginState> {
  LoginStateMachine({
    required this.userRepository,
  }) : super(WaitingFormSubmission()) {
    
    define<WaitingFormSubmission>(($) => $
      ..on<LoginFormSubmitted>(_toTryLoggingIn));

    define<TryLoggingIn>(($) => $
      ..onEnter(_login)
      ..on<LoginSucceeded>(_toSuccess)
      ..on<LoginFailed>(_toError));

    define<LoginSuccess>();
    define<LoginError>();
  }

  final UserRepository userRepository;

  TryLoggingIn _toTryLoggingIn(FormSubmitted event, state)
    => TryLoggingIn(email: event.email, password: event.password);

  LoginSucceed _toSuccess(e, s)
    => LoginSucceed();

  LoginError _toError(LoginFailed event, state)
    => LoginError(event.error);

  /// Use state's data to try login-in using the API
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

# StateMachine vs Bloc
StateMachine exposes an opinionated interface built on top of the Bloc foundation, designed to define state machine (formally a [mealy machine](https://en.wikipedia.org/wiki/Mealy_machine)).
State machines are very close to what bloc do. The main difference resides in the number of states you can have and how events are computed.

With Bloc, you register a set of event handlers that can emit new states when an event is received. Event handlers are processed no matter the current bloc's state and they can emit as many new states they want as long they inherit from the base `State` class using an `Emitter` object.

With StateMachine, you register a set of states, each one with its own set of event handlers. StateMachine can never be in a state that it hasn't been explicitly defined and it will throw an error if you try to. When an event is received, `StateMachine` searches for corresponding events handlers registered for the current state. If no event handler is found, the event is discarded. Handlers can return a state to indicate `StateMachine` should transit to this new state or `null`, to indicate no transition should happen. They are processed sequentially until one of them returns a new state or they have all been evaluated.

These differences in design bring some benefits as well some disadvantages:

**pros**
- The state machine pattern eliminates bugs and weird situations because it won't let the UI transition to a state which we don’t know about.
- It eliminates the need for code that protects other code from execution because the state machine is not accepting events that are not explicitly defined as acceptable for the current state.
- Business logic rules are written down explicitly in the state machine definition, which makes it easy to understand and maintain.

**cons**
- The state machine is less flexible than Bloc. Sometimes state machine is not adapted to express certain problems.
- State machine trend to be more verbose than blocs.

# When to use `StateMachine`?
Generally, it's recommended to use `StateMachine` where you can because it will make your code clean and robust. 

StateMachine is well suited if you can identify a set of states and easily identify what event belongs to what state. If you need to use complex event transformers or if states are too intricated so it's difficult to distinguish them, then you should probably use a `Bloc`.

# Documentation
## The state machine
The state machine uses `Bloc`'s `on<Event>` method under the hood to register a custom event dispatcher that will in turn call your methods and callbacks.

State machine's states should be defined with the `StateMachine`'s `define<State>` methods inside the constructor. You should never try to transit to a state that hasn't been explicitly defined. If the state machine detects a transition to an undefined state, it will throw an error.

### Events processing order
By default, incoming events are processed immediately and every other event received a dropped until the current event finished being processed. Since transitions are synced, it will only drop additional events received in the same event-loop iteration.

`StateMachine` use `droppable` event transformer from `BlocConcurrency` for this purpose. You can override this behavior by passing a `transformer` to the `StateMachine`'s constructor.

```dart
class MyStateMachine extends StateMachine<Event, State> {
    MyStateMachine() : super(Initial(), transformer: /** custom transformer **/) {}
}
```

### Transitions evaluation
When an event is received, the state machine will first search for the actual state definition. If the actual state is a child state, parent(s) state(s) will first be evaluated, meaning if a parent enters a transition, children will not be evaluated. Once the parent finished being evaluated, the child's state will in turn be evaluated, and so on.

If a state registers more than one handler for a given event, they are evaluated sequentially, in their definition order. As soon as an event handler enters a transition, the state machine stops evaluating handlers and transit to the new state.

## Defining states
State machine states are defined using `StateMachine`'s `define<State>` method inside the constructor. Define should be called ones for each available state.

Every defined state for a given `StateMachine<Event, State>` should inherit from `<State>` base class and should only be defined once.

```dart
class MyStateMachine extends StateMachine<Event, State> {
  MyStateMachine() : super(InitialState()) {
    define<InitialState>();
    define<OtherState>();
  }
}
```

`define<State>` method takes an optional builder function as parameter that could be used to register event handlers and side effect callbacks for the defined state.

The builder function takes a `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` exposes methods needed to register transitions and callbacks.

```dart
define<State>((StateDefinitionBuilder builder) {
  builder.onEnter((State state) { /* Side effect */ }) 
  builder.on<Event>((Event event, State state) => NextState()); //transition to NextState
  return builder;
});
```

This syntax is very verbose but hopefully thanks to the dart [cascade](https://dart.dev/guides/language/language-tour#cascade-notation) notation you could write it like so:

```dart
 define<State>(($) => $
  ..onEnter((State state) {}) 
  ..on<Event>((Event event, State state) => NextState());
```

### Event handlers
Event handlers are registered for a given state using `StateDefinitionBuilder`'s `on<Event>` method. For a given `StateMachine<Event, State>`, every registered event should inherit from `<Event>` base class. You can register as many handlers you want for a given state. You can also register multiple handlers for the same event.

Event handlers have the following signature:
```dart
State? Function(DefinedEvent, DefinedState);
```
If the returned state is not null, it is considered a transition, and the state machine transit to this new state. Otherwise, no transition append and next event handlers are evaluated.

> 🚨 Event handlers are only evaluated if the event is received while the state machine is in the state for which the handler is registered.

> 🚨 **If a new state is returned from a transition where `newState == state`, the new state will be ignored**. If you're using a state that contains data, make sure you've implemented `==` operator. You could use `freezed` or `equatable` packages for this purpose.

**Here an example of three event handlers registered for `InitialState`.**
```dart
class MyStateMachine extends StateMachine<Event, State> {
  MyStateMachine() : super(InitialState()) {
    define<InitialState>(($) => $
      ..on<SomeEvent>((SomeEvent e, InitialState s) => null)
      ..on<SomeEvent>((SomeEvent e, InitialState s) => SecondState())
      ..on<OtherEvent>((SomeEvent e, InitialState s) => ThirdState())
    );

    define<SecondState>();
    define<ThirdState>();
  }
}
```
### Side effects
Side effects are callback functions that you can register to react to the state's lifecycle events. They are generally a good place to request APIs or start async computations. 
You have access to 3 different side effects:
**onEnter** is called when State Machine enters a state. If `State` is the initial `StateMachine`'s state, onEnter will be called during state machine initialization.
**onChange** is called when a state transitions to itself. `onChange` **is not** called if `state == nextState` or when the state machine enters the state for the first time.
**onExit** is called before State Machine's exit a state.
You can register a side effect for a given state using `StateDefinitionBuilder`'s `onEnter`, `onChange` or `onExit` methods.

```dart
define<State>((b) => b
  ..onEnter((State state) { /* called when entering State */ })
  ..onChange((State current, State next) { /* called when State data changed */ })
  ..onExit((State state) { /* called when exiting State */ })
```

You can give async function as parameter for side effects, but remember they will **not** be awaited.
```dart
define<State>((b) => b
  ..onEnter((State state) async { /* not awaited */ })
```

## Nesting states
`StateMachine` supports state nesting. This is convenient for defining common event handlers or side effects for a group of states.
You can define a nested state using `StateDefinitionBuilder`'s `define<ChildState>` method. This method behaves the same way as top-level define calls.
You could register event handlers and side effects for the nested state like a normal state.

The only restriction you have when defining a nested state is that the child state should be a sub-class of the parent state.

```dart
define<WaitingFormSubmission>(($) => $
  ..on<LoginFormSubmitted>(_transitToTryLoggingIn)
  ..define<LoginError>()
);
```

In the example above, the `LoginError` state is a child state of `WaitingFormSubmission`. `WaitingFormSubmission` and `LoginError` are both valid states that can transit to the `TryLoginIn` state, but `LoginError` carries an additional error the UI will display.

A state can have any number of child states as long their only defined once. Nested states have access to a `StateDefinitionBuilder` like normal states so they can register an event handler, side effect, or in turn, nested states.

```dart
define<Parent>(($) => $
  ..define<Child1>(($) => $
    ..onEnter(...)
    ..onChange(...)
    ..onExit(...)
    ..on<Event1>(...)
    ..define<Child2>(($) => $
      ...
    )
  )
);
```

### Nested states event handlers
When an event is received, the state machine searches the current state definition. If it's a nested state, the state machine will evaluate each parent state, from the higher ones in the hierarchy to the lowest ones before evaluating the current state. That way, if a parent state event handler handles an event and returns a new state, the child's event handlers will not be evaluated.

### Nested state side effects
Parent's side effects can be triggered when the state machine enters, move or exit from one of its child's state.
The table below describes how side effects are triggered for parent and child states.

> 🚨 A state is considered a child as long as it's below the parent state in the state hierarchy.

|          | Parent                                                                                | Child                                   |
|----------|---------------------------------------------------------------------------------------|-----------------------------------------|
| onEnter  | Called when entering this state or any of its children                                | Called when entering the state          |
| onChange | Called transitioning from itself or one of its child to itself or one of its children | Called transitioning to itself          |
| onExit   | Called when next state isn't this state or one of its children                        | Called when next state isn't this state |

# Examples
You can find usage examples in the repository's [example folder](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples). These examples are re-implementations of bloc's examples using a state machine. New examples will be added over time.
* [Timer](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/flutter_timer_state_machine)
* [Infinite list](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/infinite_list_state_machine)

# Issues and feature requests
If you find a bug or want to see an additional feature, please fill on the issue on [github](https://github.com/Pierre2tm/state_machine_bloc/issues/new).

## Additional resources
* [You are managing state? Think twice.](https://krasimirtsonev.com/blog/article/managing-state-in-javascript-with-state-machines-stent)
* [The rise of state machine](https://www.smashingmagazine.com/2018/01/rise-state-machines/)
* [Robust React User Interfaces with Finite State Machines](https://css-tricks.com/robust-react-user-interfaces-with-finite-state-machines/)
