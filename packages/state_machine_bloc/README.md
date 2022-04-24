<p align="center">
<img src="https://raw.githubusercontent.com/Pierre2tm/state_machine_bloc/main/docs/assets/state_machine_bloc_logo_full.png" height="100" alt="State machine Bloc" />
</p>

<p align="center">
<a href="https://github.com/Pierre2tm/state_machine_bloc"><img src="https://img.shields.io/github/stars/Pierre2tm/state_machine_bloc.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="Star on Github"></a>
<a href="https://github.com/tenhobi/effective_dart"><img src="https://img.shields.io/badge/style-effective_dart-40c4ff.svg" alt="style: effective dart"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/felangel/bloc"><img src="https://tinyurl.com/bloc-library" alt="Bloc Library"></a>
</p>
<p align="center">⚠️ state_machine_bloc is not an official bloc package ⚠️</p>

state_machine_bloc is an extension to the bloc state management library which provide a utility class to create blocs that behave like finite state machines. Event routing and filtering are done under the hood for you so you can focus on building state machine logic.

This package uses a flexible declarative API to conveniently describe simple to complex state machines.

**state_machine_bloc supports:**
* ✅ Easy state machine definition
* ✅ Shared or per-state data
* ✅ States lifecycle events
* ✅ Guard conditions on transitions
* ✅ Nested states without depth limit

# Index
* <a href="#How-to-use">How to use</a>
* <a href="#StateMachine-vs-Bloc">StateMachine vs Bloc</a>
* <a href="#when-to-use-statemachine">When to use StateMachine?</a>
* <a href="#Documentation">Documentation</a>
  * <a href="#The-state-machine">The state machine</a>
    * <a href="#Events-concurrency">Events processing order</a>
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
State machines are created by extending `StateMachine`, a new class introduced by this package. `StateMachine` itself inherits from `Bloc` class, meaning states machines created using this package **are** blocs and therefore compatible with the entire bloc's ecosystem.

`StateMachine` class has been designed to be as lightweight as possible to avoid interfering with `Bloc` inner behavior. Under the hood, `StateMachine` uses the `Bloc`'s `on<Event>` method with a custom event mapper to call your callbacks based on the state machine's definition you've provided.

State machine's states and transitions are defined using a new method, `define<State>`, which is similar to `Bloc`'s `on<Event>`. By calling `define<State>`, you register `State` as part of the machine's set of allowed states. Each state can have its own set of events handlers, lifecycle events, and transitions.

The following state machine represents a login page's bloc that first wait for the user to submit the form, then try to log in using the API, and finally change its state to success or error based on API return. Bellow, you can see its graph representation and the corresponding code.

<table>
  <tbody>
    <tr>
      <td width="60%">
        <img alt="Login state machine code" src="https://raw.githubusercontent.com/Pierre2tm/state_machine_bloc/main/docs/assets/readme/simple_login_sm_code.png" />
      </td>
      <td width="40%">
        <img alt="Login state machine graph" src="https://raw.githubusercontent.com/Pierre2tm/state_machine_bloc/main/docs/assets/readme/simple_login_sm_graph_horizontal.png"/>
      </td>
    </tr>
  </tbody>
</table>

`StateMachine` **is** a `Bloc`, so you could use it in the same way as `Bloc`:

```dart
BlocProvider(
  create: (_) => LoginStateMachine(),
  child: ...,
);

...

BlocBuilder<LoginStateMachine, LoginState>(  
  builder: ...,
);
```

# StateMachine vs Bloc
State machines are very close to what bloc already do. The main differences reside in the number of states you can have and how events are computed.

With `Bloc`, you register a set of event handlers that can emit new states when corresponding events are received. Event handlers are processed no matter the current bloc's state and they can emit as many new states they want as long they inherit from the base `State` class.

With StateMachine, you register a set of states, each one with its own set of event handlers. StateMachine can never be in a state that it hasn't been explicitly defined and it will throw an error if you try to. When an event is received, `StateMachine` searches for corresponding events handlers registered for the current state. If no event handler is found, the event is discarded. Handlers can return a state to indicate `StateMachine` should transit to this new state or `null`, to indicate no transition should happen. Event handlers are processed sequentially until one of them returns a new state or they have all been evaluated.

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

StateMachine is well suited if you can identify a set of states and easily identify what event belongs to what state. If you need to use complex event transformers or if states are too intricated so it's difficult to distinguish them, you should probably use a `Bloc`.

# Documentation
## The state machine
The state machine uses `Bloc`'s `on<Event>` method under the hood with a custom event dispatcher that will in turn call your methods and callbacks.

State machine's states should be defined with the `StateMachine`'s `define<State>` methods inside the constructor. You should never try to transit to a state that hasn't been explicitly defined. If the state machine detects a transition to an undefined state, it will throw an error.

> 🚨 You should **NEVER** use `on<Event>` method inside a StateMachine.

Each state has its own set of event handlers and side effects callbacks:
* **Event handlers** react to an incoming event and can emit the next machine's state. We call this a _transition_.
* **Side effects** are callback functions called depending on state lifecycle. You have access to three different side effects: `onEnter`, `onExit`, and `onChange`.

When an event is received, the state machine will first search for the actual state definition. Each current state's event handler that matches the received event type will be evaluated. If multiple events handlers match the event type, they will be evaluated in their **definition order**. As soon as an event handler returns a non-null state (we call this _entering a transition_), the state machine stops evaluating events handlers and transit to the new state immediately.

### Events concurrency
By default, if multiple incoming events are received during **the same event loop**, the first one is processed and every other is dropped. You can override this behavior by passing a `transformer` to the `StateMachine`'s constructor.

```dart
class MyStateMachine extends StateMachine<Event, State> {
    MyStateMachine() : super(Initial(), transformer: /** custom transformer **/) {}
}
```

## Defining states
State machine states are defined using `StateMachine`'s `define<State>` method inside the constructor. Define should be called ones for each available state. Every defined state for a given `StateMachine<Event, State>` should inherit from `<State>` base class and should only be defined once.

```dart
class MyStateMachine extends StateMachine<Event, State> {
  MyStateMachine() : super(InitialState()) {

    // InitialState definition
    define<InitialState>(($) => $
      // onEnter side effect
      ..onEnter((InitialState state) { /** ... **/ })

      // onChange side effect
      ..onChange((InitialState state, InitialState nextState) { /** ... **/ })

      // onExit side effect
      ..onExit((InitialState state) { /** ... **/ })

      // transition to OtherState when receiving SomeEvent
      ..on<SomeEvent>((SomeEvent event, InitialState state) => OtherState())
    );

    // OtherState definition
    define<OtherState>();
  }
}
```

`define<State>` method takes an optional builder function as parameter that could be used to register event handlers and side effect callbacks for the defined state.

The builder function takes a `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` exposes methods necessary to register the defined state's transitions and side effects callbacks.

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
If the returned state is not null, it is considered a _transition_ and the state machine will transit immediately to this new state. Otherwise, no transition append, and the next event handler is evaluated.

> 🚨 Event handlers are only evaluated if the event is received while the state machine is in the state for which the handler is registered.

> 🚨 **If a new state is returned from a transition where `newState == state`, the new state will be ignored**. If you're using a state that contains data, make sure you've implemented `==` operator. You could use `freezed` or `equatable` packages for this purpose.

**Example of three event handlers registered for `InitialState`.**
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
**onEnter** is called when State Machine enters a state. If `State` is the initial `StateMachine`'s state, `onEnter` will be called during state machine initialization.
**onChange** is called when a state transitions to itself. `onChange` **is not** called if `state == nextState` or when the state machine enters this state for the first time.
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
You could register event handlers and side effects for the nested state like any normal state.

The only restriction you have when defining a nested state is that the child state should be a sub-class of the parent state.

```dart
define<WaitingFormSubmission>(($) => $
  ..on<LoginFormSubmitted>(_transitToTryLoggingIn)
  ..define<LoginError>()
);
```

In the example above, the `LoginError` state is a child state of `WaitingFormSubmission`. `WaitingFormSubmission` and `LoginError` are both valid states that can transit to the `TryLoginIn` state, but `LoginError` carries an additional error the UI will display.

A state can have any number of child states as long they are only defined once. Nested states have access to a `StateDefinitionBuilder` like normal states so they can register their event handlers, side effects, or in turn, nested states.

```dart
define<Parent>(($) => $
  ..define<Child1>(($) => $
    ..onEnter(...)
    ..onChange(...)
    ..onExit(...)
    ..on<Event1>(...)
    ..define<Child2>(($) => $
      ...
    ) // Child2
  ) // Child1
); // Parent
```

### Nested states event handlers
When an event is received, the state machine searches the current state definition. If it's a nested state, the state machine will evaluate each parent state, from the higher ones in the hierarchy to the lowest ones before evaluating the current state. If a parent state event handler handles an event and returns a new state, the child's event handlers will not be evaluated.

### Nested state side effects
Parent's side effects can be triggered when the state machine enters, move or exit from one of its child's state.
The table below describes how side effects are triggered for the parent and child states.

> 🚨 A state is considered a child as long as it's below the parent state in the state hierarchy.

|          | Parent                                                                                | Child                                   |
|----------|---------------------------------------------------------------------------------------|-----------------------------------------|
| onEnter  | Called when entering this state or any of its children                                | Called when entering the state          |
| onChange | Called transitioning from itself or one of its child to itself or one of its children | Called transitioning to itself          |
| onExit   | Called when next state isn't this state or one of its children                        | Called when next state isn't this state |

# Examples
You can find usage examples in the repository's [example folder](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples). These examples are re-implementations of bloc's examples using state machines. New examples will be added over time.
* [Timer](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/flutter_timer_state_machine)
* [Infinite list](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/infinite_list_state_machine)

# Issues and feature requests
If you find a bug or want to see an additional feature, please open an issue on [github](https://github.com/Pierre2tm/state_machine_bloc/issues/new).

## Additional resources
* [You are managing state? Think twice.](https://krasimirtsonev.com/blog/article/managing-state-in-javascript-with-state-machines-stent)
* [The rise of state machine](https://www.smashingmagazine.com/2018/01/rise-state-machines/)
* [Robust React User Interfaces with Finite State Machines](https://css-tricks.com/robust-react-user-interfaces-with-finite-state-machines/)
