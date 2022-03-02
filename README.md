# BLoC State Machine

An extension to the bloc state management library which lets you create State Machine using a declarative API.

🚧 Work in progress. Do not use in production 🚧

## Overview

`bloc_state_machine` export a `StateMachine` class, a new kind of bloc designed to declare state machines using a nice builder API.
It can be used in the same way as `Cubit` and `Bloc` and it aims to be compatible with the rest of the ecosystem.

`bloc_state_machine` supports:

- Storing data in states
- Defining state transitions based on event
- Applying guard conditions to transitions
- sideEffects
- onEnter/onExit

State machines shines is in their expressiveness, predictability, and robustness:

- This makes it easy to know all possible states of business logic

* They eliminate bugs and weird situations because they won't let the UI transition to a state which we don’t know about.
* This eliminates the need for code that protects other codes from execution because They do not accept input that is not explicitly defined as acceptable for the current state.

```dart
class Timer extends StateMachine<Event, State> {
    Timer() : super(Running()) {
        define<Running>((b) => b
            ..onEnter((Running currentState) => print("on enter running state"))
            ..on<Stopped>((Stopped event, Running currentState) => Paused()),
        );

        define<Paused>((b) => b
            ..onExit((Running currentState) => print("on exit paused state"))
            ..on<Started>((Started event, Paused currentState) => Running()),
        );
    }
}
```

### Additional ressources

* [You are managing state? Think twice.](https://krasimirtsonev.com/blog/article/managing-state-in-javascript-with-state-machines-stent)
* [The rise of state machine](https://www.smashingmagazine.com/2018/01/rise-state-machines/)
* [Robust React User Interfaces with Finite State Machines](https://css-tricks.com/robust-react-user-interfaces-with-finite-state-machines/)

## Project Status

This project is very early and in active development. A basic Proof of Concept has been done so you can try it already. Any opinions, feedback, thought and contributions are welcome.

## Roadmap

* [X] PoC
* [ ] Make timer state machine example pass all original unit tests
* [ ] Implements more bloc's example and maybe try new one
* [ ] Define specs
* [ ] Write some documentation
* [ ] Alpha implementation

**features to be explored**

* [ ] nested states machines
* [ ] dedicated flutter builder/listener widgets
* [ ] make state machine usable with other library than bloc

## Getting Started

### Install

add this to your `pubspec.yaml`

```dart
bloc_state_machine:
  git:
    url: git@github.com:Pierre2tm/bloc_state_machine.git
    path: packages/bloc_state_machine
```

then run `flutter pub get`.

import the package

```dart
import 'package:bloc_state_machine/bloc_state_machine.dart'
```

### Usage

Declare your `StateMachine`:

*timer.dart*

```dart
import 'package:bloc_state_machine/bloc_state_machine.dart';

class Event {}
class Started extends Event {}
class Stopped extends Event {}

class State {}
class Running extends State {}
class Paused extends State {}


```dart
class Timer extends StateMachine<Event, State> {
    Timer() : super(Running()) {
        define<Running>((b) => b
            ..onEnter((Running currentState) => print("on enter running state"))
            ..on<Stopped>((Stopped event, Running currentState) => Paused()),
        );

        define<Paused>((b) => b
            ..onExit((Running currentState) => print("on exit paused state"))
            ..on<Started>((Started event, Paused currentState) => Running()),
        );
    }
}
```

Then use it as a regular `Bloc`:

*timer_page.dart*

```dart

BlocProvider(
    create: (_) => Timer(ticker: Ticker()),
    child: const TimerView(),
);

```

TODO: better examples
TODO: detailed usage