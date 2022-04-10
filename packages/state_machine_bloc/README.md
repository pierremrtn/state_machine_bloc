`state_machine_bloc` export a `StateMachine`, a lightweight class that inherit from `Bloc` and expose convenient methods to describe state machines.
`StateMachine` **is** a `Bloc`, meaning that you can use it in the same way as a regular bloc and it's compatible with the rest of the ecosystem.

The package use a flexible declarative API to conveniently describe simples to complex state machines. `StateMachine` route and filter events for you based on the state machine definition you've provided so you can focus on building app logic.

`state_machine_bloc` enable you to:
* ✅ Easily define state machine's states and their transitions
* ✅ Store different data for each states
* ✅ Register callbacks to state's lifecycle events
* ✅ Apply guard conditions on transitions
* ✅ Nest states without depth limit

# Index
* How to use
* StateMachine vs Bloc
* When to use StateMachine
* Documentation
    * The state machine
        * event processing order
        * transitions evaluation
    * defining states
        * event handlers
        * side effects
    * nesting states
* Examples
* Additional resources

# How to use
`StateMachine` expose a `define<State>` method, similar to `Bloc`'s `on<Event>`, used to define one of the state machine's possible states. Its takes a builder function as parameter that lets you register events handlers and side effect for the defined state.

> 🚨 You should **NEVER** use `on<Event>` method inside a StateMachine

`define`'s state definition builder function takes a `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` expose methods to register event handlers and side effects.

**Event handlers** react to an incoming event and can emit the next machine's state. We call this a _transition_.

**Side effects** are callback function called depending on state lifecycle. You have access to three differents side effects: `onEnter`, `onExit` and `onChange`.

**Example of a login-in form state machine:**
```dart
import 'package:state_machine_bloc/state_machine_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginStateMachine extends StateMachine<LoginEvent, LoginState> {
    // Define each state machine's state inside 
    // the constructor using define method
    LoginStateMachine({
        required this.userRepository,
    }) : super(WaitingFormSubmission()) {

        // Wait for the user to submit the form
        define<WaitingFormSubmission>(($) => $
            ..on<LoginFormSubmitted>(_transitToTryLoggingIn));

        // Send form data to the API
        define<TryLoggingIn>(($) => $
            ..onEnter(_login)
            ..on<LoginSucceeded>(_transitToSuccess)
            ..on<LoginFailed>(_transitToError));

        // Redirect user or display an error
        define<LoginSuccess>();
        define<LoginError>();
    }

    final UserRepository userRepository;

    // Takes form data sent from the UI and save it in the next state
    TryLoggingIn _transitToTryLoggingIn(
        FormSubmitted event, state,
    ) => TryLoggingIn(
        email: event.email,
        password: event.password,
    );

    // Shortcut syntax since we don't use event or state
    LoginSucceed _transitToSuccess(e, s) => LoginSucceed();

    LoginError _transitToError(LoginFailed event, state)
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
StateMachine expose an opinionated interface built on top of the Bloc foundation, designed to define state machine (formally a [mealy machine](https://en.wikipedia.org/wiki/Mealy_machine)).
State machines are very close to what bloc do. The main main difference reside in the number of sates you can have and how events are computed.

With Bloc, you register a set of event handler that can emits new states when an event is received. Event handlers are processed no matter the current bloc's state and they can emit as many new states they want as long it inherit from the base `State` class using an `Emitter` object.

With State machine, you register a set of state, each one with its own set of event handlers. StateMachine can never be in a state that it hasn't been explicitly defined and it will throw an error if you try to. When an event is received, `StateMachine` search for corresponding events handlers registered for the current state. If no event handler is found, event is discarded. Handlers can return a state to indicate `StateMachine` should transit to this new state or `null`, to indicate no transition should happen. They are processed sequentially until one of them return a new state or they have all been evaluated.

Theses difference in design bring some benefits as well some disadvantages:

**pros**
- The state machine pattern eliminates bugs and weird situations because it wont let the UI transition to state which we don’t know about.
- It eliminate the need of code that protects other code from execution because the state machine is not accepting events that are not explicitly defined as acceptable for the current state.
- Business logic rules are written down explicitly in the state machine definition, which make it easy to understand and maintain.

**cons**
- The state machine is less flexible than Bloc. Sometime state machine is not adapted to express certain problems.
- State machine trend to be more verbose than bloc.

# When to use `StateMachine` ?
Generally, it's recommended to use `StateMachine` where you can because it will make your code clean and robust. 

StateMachine is well suited if you can identify a set of states and easily identify what event belongs to what state. If you need to use complex event transformers or if states are too intricated so it's difficult to distinguish them, then you should probably use a `Bloc`.

# Documentation
## The state machine
The state machine use `Bloc`'s `on<Event>` method under the hood to register a custom event dispatcher that will in turn call your own methods and callbacks.

State machine's states should be defined with the `StateMachine`'s `define<State>` methods inside the constructor. You should never try to transit to a state that hasn't been explicitly defined. If state machine detect a transition to an undefined state, it will throw an error.

### event processing order
By default, incoming events are processed imediatly and every other event received a dropped until the current event finished being processed. Since transitions are sync, it will only drop additional events received in the same event-loop iteration.

`StateMachine` use `droppable` event transformer from `BlocConcurrency` for this purpose. You can override this behavior by passing a `transformer` to the `StateMachine`'s constructor.

```dart
class MyStateMachine extends StateMachine<Event, State> {
    MyStateMachine() : super(Initial(), transformer: /** custom transformer **/) {}
}
```

### transitions evaluation
When an event is received, the state machine will first search for the actual state definition. If the actual state is a child state, parent(s) state(s) will first be evaluated, meaning if a parent enter a transition, child will not being evaluated. Once parent finished being evaluated, child state will in turn being evaluated an so on.

If a state register more than once handler for a given event, they are evaluated sequentialy, in their definition order. As soon an event handler enter a transition, state machine stop evaluating handlers and transit to the new state.

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

The builder function takes an `StateDefinitionBuilder` as parameter and should return it. `StateDefinitionBuilder` exposes method needed to registers transitions and callbacks.

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

### event handlers
Event handler are registered for a given state using `StateDefinitionBuilder`'s `on<Event>` method. For a given `StateMachine<Event, State>`, every registered event should inherit from `<Event>` base class. You can register as many handler you want for a given state. You can also register multiple handlers for the same event.

Event handlers have the following signature:
```dart
State? Function(DefinedEvent, DefinedState);
```
If the returned state is not null, it is considered as a transition and the state machine transit to this new state. Otherwise, no transition append and next event handlers are evaluated.

> 🚨 Event handlers are only evaluated if event is received while the state machine is its corresponding defined state.

> 🚨 **If a new state is returned from a transition where `newState == state`, the new state will be ignored**. If you're using state that contain data, make sure you've implemented `==` operator. You could use `freezed` or `equatable` package for this purpose.

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
### Side Effects
Side effects are callback function that you can register to react on state's lifecycle events. They are generally a good place to request APIs or start async computations. 
You have access to 3 different side effects:
**onEnter** is called when State Machine enters a state. If `State` is the initial `StateMachine`'s state, onEnter will be called at during State machine initialization.
**onChange** is called when a state transition to itself. `onChange` **is not** called if `state == nextState` or when the state machine enter the state for the first time.
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
`StateMachine` support state nesting. This is convenient for defining common event handlers or side effects for a group of states.
You can define a nested state using `StateDefinitionBuilder`'s `define<ChildState>` method. This method behave the same way than top-level define calls.
You could register event handlers and side effect for the nested state like a normal state.

The only restriction you have when defining a nested state is that the child state should be a sub-class of the parent state.

```dart
define<WaitingFormSubmission>(($) => $
    ..on<LoginFormSubmitted>(_transitToTryLoggingIn)
    ..define<LoginError>()
);
```

In the example above, `LoginError` state is a child state of `WaitingFormSubmission`. `WaitingFormSubmission` and `LoginError` are both valid state that can transit to `TryLoginIn` state, but `LoginError` carry an additional error the UI will display.

A state can have any number of child state as long their only defined once. Nested states have access to a `StateDefinitionBuilder` like normal states so they can register event handler, side effect or in turn nested states.

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
When and event is received, state machine search the current state definition. If it's a nested state, the state machine will evaluate each parent states, from the higher ones in the hierarchy to the lowest ones in order to evaluate the current state. That way, is a parent state event handler handle an event and return a new state, child state's event handlers will not be evaluated.

### Nested state side effects
Parent's side effects can be triggered when the state machine enter, move or exit from one of its child state.
The table bellow describe how side effect are triggered for parent and child states.

> 🚨 A state is considered as child as long as it's bellow the parent state in the state hierarchy.

|          | Parent                                                                             | Child                                   |
|----------|------------------------------------------------------------------------------------|-----------------------------------------|
| onEnter  | Called when entering this state or any of its child                                | Called when entering the state          |
| onChange | Called transitioning from itself or one of its child to itself or one of its child | Called transitioning to itself          |
| onExit   | Called when next state isn't this state or one of its child                        | Called when next state isn't this state |

# Examples
You can find usage examples in the repository's [example folder](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples). Theses example are re-implementation of bloc's examples using a state machine. New examples will be added over time.
* [Timer](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/flutter_timer_state_machine)
* [Infinite list](https://github.com/Pierre2tm/state_machine_bloc/tree/main/examples/infinite_list_state_machine)

# Issues and feature requests
If you find a bug or want to see an additional feature, please fill on issue on [github](https://github.com/Pierre2tm/state_machine_bloc/issues/new).

## Additional ressources
* [You are managing state? Think twice.](https://krasimirtsonev.com/blog/article/managing-state-in-javascript-with-state-machines-stent)
* [The rise of state machine](https://www.smashingmagazine.com/2018/01/rise-state-machines/)
* [Robust React User Interfaces with Finite State Machines](https://css-tricks.com/robust-react-user-interfaces-with-finite-state-machines/)
