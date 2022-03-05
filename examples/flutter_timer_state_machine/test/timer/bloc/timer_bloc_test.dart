import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_timer_state_machine/timer/timer.dart';
import 'package:flutter_timer_state_machine/ticker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTicker extends Mock implements Ticker {}

void main() {
  group('TimerStateMachine', () {
    late Ticker ticker;

    setUp(() {
      ticker = MockTicker();

      when(() => ticker.tick(ticks: 5)).thenAnswer(
        (_) => Stream<int>.fromIterable([5, 4, 3, 2, 1]),
      );
    });

    test('initial state is TimerInitial(60)', () {
      expect(
        TimerStateMachine(ticker: ticker).state,
        TimerInitial(60),
      );
    });

    blocTest<TimerStateMachine, TimerState>(
      'emits TickerRunInProgress 5 times after timer started',
      build: () => TimerStateMachine(ticker: ticker),
      act: (bloc) => bloc.add(const TimerStarted(duration: 5)),
      expect: () => [
        TimerRunInProgress(5),
        TimerRunInProgress(4),
        TimerRunInProgress(3),
        TimerRunInProgress(2),
        TimerRunInProgress(1),
      ],
      verify: (_) => verify(() => ticker.tick(ticks: 5)).called(1),
    );

    blocTest<TimerStateMachine, TimerState>(
      'emits [TickerRunPause(2)] when ticker is paused at 2',
      build: () => TimerStateMachine(ticker: ticker),
      seed: () => TimerRunInProgress(2),
      act: (bloc) => bloc.add(TimerPaused()),
      expect: () => [TimerRunPause(2)],
    );

    blocTest<TimerStateMachine, TimerState>(
      'emits [TickerRunInProgress(5)] when ticker is resumed at 5',
      build: () => TimerStateMachine(ticker: ticker),
      seed: () => TimerRunPause(5),
      act: (bloc) => bloc.add(TimerResumed()),
      expect: () => [TimerRunInProgress(5)],
    );

    blocTest<TimerStateMachine, TimerState>(
      'emits [TickerInitial(60)] when timer is restarted',
      build: () => TimerStateMachine(ticker: ticker),
      seed: () => TimerRunInProgress(3),
      act: (bloc) => bloc.add(TimerReset()),
      expect: () => [TimerInitial(60)],
    );

    blocTest<TimerStateMachine, TimerState>(
      'emits [TimerRunInProgress(3)] when timer ticks to 3',
      build: () => TimerStateMachine(ticker: ticker),
      seed: () => TimerRunInProgress(4),
      act: (bloc) => bloc.add(TimerTicked(duration: 3)),
      expect: () => [TimerRunInProgress(3)],
    );

    blocTest<TimerStateMachine, TimerState>(
      'emits [TimerRunComplete()] when timer ticks to 0',
      seed: () => TimerRunInProgress(1),
      build: () => TimerStateMachine(ticker: ticker),
      act: (bloc) => bloc.add(TimerTicked(duration: 0)),
      expect: () => [TimerRunComplete()],
    );
  });
}
