import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_timer_state_machine/ticker.dart';
import 'package:bloc_state_machine/bloc_state_machine.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerStateMachine extends StateMachine<TimerEvent, TimerState> {
  TimerStateMachine({required Ticker ticker})
      : _ticker = ticker,
        super(TimerInitial(_duration)) {
    define<TimerInitial>((b) => b
      ..on<TimerStarted>(
        (event, state) => TimerRunInProgress(event.duration),
      ));

    define<TimerRunInProgress>((b) => b
      ..onEnter((state) => _startTicker(state.duration))
      ..on<TimerTicked>(_onTicked)
      ..on<TimerPaused>(_onPaused)
      ..on<TimerReset>(_onReset));

    define<TimerRunPause>((b) => b
      ..on<TimerResumed>(_onResumed)
      ..on<TimerReset>(_onReset));

    define<TimerRunComplete>(
      (b) => b..on<TimerReset>(_onReset),
    );
  }

  final Ticker _ticker;
  static const int _duration = 60;

  StreamSubscription<int>? _tickerSubscription;

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  _startTicker(int duration) {
    _tickerSubscription?.cancel();
    // _tickerSubscription = _ticker.tick(ticks: duration)
    // .listen((duration) => add(TimerTicked(duration: duration)));
    _tickerSubscription = _ticker.tick(ticks: duration).listen((duration) {
      try {
        add(TimerTicked(duration: duration));
      } catch (e) {
        print(e);
      }
    });
  }

  TimerRunPause _onPaused(TimerPaused event, TimerRunInProgress state) {
    _tickerSubscription?.pause();
    return TimerRunPause(state.duration);
  }

  TimerRunInProgress _onResumed(TimerResumed resume, TimerRunPause state) {
    _tickerSubscription?.resume();
    return TimerRunInProgress(state.duration);
  }

  TimerInitial _onReset(TimerReset event, TimerState state) {
    _tickerSubscription?.cancel();
    return TimerInitial(_duration);
  }

  TimerState _onTicked(TimerTicked event, TimerRunInProgress state) {
    return event.duration > 0
        ? TimerRunInProgress(event.duration)
        : TimerRunComplete();
  }
}
