## 0.0.1-dev.3
* `StateMachine` now use `droppable` event transformer instead of `sequential`
* Transition are now synchronous.
* Fix: onEnter/onExit child state's side effects wasn't triggered when parent changed
* Parents states are not forbidden states anymore
* Improved documentation
* Add unit tests
* Add infinite List example

## 0.0.1-dev.2
* `StateMachine` now extends `Bloc` instead of `BlocBase`.
* Support for nested states.
* Side effect rework

## 0.0.1-dev.1
* proof of concept
