import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/app/shared/constants.dart';
import 'package:tv/session/bloc/session_bloc.dart';
import 'package:tv/session/bloc/session_event.dart';
import 'package:tv/session/bloc/session_state.dart';
import 'package:tv/session/model/session.dart';
import 'package:tv/session/service/session_service.dart';
import '../../helpers/stub_workout_service.dart';

import '../../helpers/scripted_session_service.dart';
import '../../helpers/test_fixtures.dart';

/// Bringt den Bloc in den Auswahl-Zustand (T2) – der Ausgangspunkt für
/// alle Phasen-Tests (Trainer-Start kommt von hier).
void _enterSelection(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  bloc.add(const SessionStarted());
  async.flushMicrotasks(); // createSession → T1 (Warten)
  service.emit(const ParticipantsChanged([trainer]));
  async.flushMicrotasks(); // Zähler auf 1
  service.emit(const SelectionStarted());
  async.flushMicrotasks(); // → T2 (Auswahl)
}

/// Bringt den Bloc in den Warm-up-Zustand (T4): Auswahl → Countdown (3 s)
/// → advancePhase() → Warm-up-Bestätigung.
void _enterWarmup(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  _enterSelection(async, service, bloc);
  service.emit(
    const PhaseChanged(phase: SessionPhase.countdown, workoutName: 'Ganzkörper-Blitz'),
  );
  async.flushMicrotasks(); // → T3 (Countdown)
  async.elapse(const Duration(seconds: AppConstants.countdownSeconds));
  async.flushMicrotasks(); // Countdown = 0 → advancePhase()
  service.emit(
    const PhaseChanged(phase: SessionPhase.warmup, exercise: warmupExercise),
  );
  async.flushMicrotasks(); // → T4 (Warm-up)
}

void main() {
  group('T3 – Countdown (Bloc)', () {
    test('Trainer-Start erzeugt Countdown mit 3 s + Workout-Titel (T3-T1)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        // Trainer tippt „Workout starten" (start_workout-RPC → Bestätigung).
        service.emit(
          const PhaseChanged(phase: SessionPhase.countdown, workoutName: 'Ganzkörper-Blitz'),
        );
        async.flushMicrotasks();

        final state = bloc.state;
        expect(state, isA<SessionCountdownState>());
        final countdown = state as SessionCountdownState;
        expect(countdown.workoutName, 'Ganzkörper-Blitz');
        expect(countdown.secondsRemaining, AppConstants.countdownSeconds); // 3
        bloc.close();
      });
    });

    test('Timer zählt sekündlich herunter (T3-T2)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        service.emit(
          const PhaseChanged(phase: SessionPhase.countdown, workoutName: 'Ganzkörper-Blitz'),
        );
        async.flushMicrotasks();

        int remaining() => (bloc.state as SessionCountdownState).secondsRemaining;
        expect(remaining(), AppConstants.countdownSeconds);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(remaining(), AppConstants.countdownSeconds - 1);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(remaining(), AppConstants.countdownSeconds - 2);

        // Noch kein Phase-Wechsel, solange der Countdown läuft.
        expect(service.advancePhaseCallCount, 0);
        bloc.close();
      });
    });

    test('bei Countdown = 0 wird advancePhase() genau einmal aufgerufen (T3-T3)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        service.emit(
          const PhaseChanged(phase: SessionPhase.countdown, workoutName: 'Ganzkörper-Blitz'),
        );
        async.flushMicrotasks();

        // 3 s Countdown ablaufen lassen.
        async.elapse(const Duration(seconds: AppConstants.countdownSeconds));
        async.flushMicrotasks();

        expect(service.advancePhaseCallCount, 1); // genau einmal
        // Der Countdown-Zustand bleibt bis zur serverseitigen Bestätigung.
        expect(bloc.state, isA<SessionCountdownState>());

        // Server-Bestätigung: Warm-up (T4).
        service.emit(
          const PhaseChanged(phase: SessionPhase.warmup, exercise: warmupExercise),
        );
        async.flushMicrotasks();

        expect(bloc.state, isA<SessionWarmupState>());
        bloc.close();
      });
    });
  });

  group('T4 – Warm-up (Bloc)', () {
    test(
        'PhaseChanged(warmup, exercise) erzeugt Warm-up-Zustand mit 20 s + Übung (T4-T1)',
        () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterWarmup(async, service, bloc);

        final state = bloc.state;
        expect(state, isA<SessionWarmupState>());
        final warmup = state as SessionWarmupState;
        expect(warmup.exercise, warmupExercise); // Hampelmann
        expect(warmup.secondsRemaining, warmupExercise.executionSeconds); // 20 s
        bloc.close();
      });
    });

    test('Timer zählt sekündlich 20 → 19 herunter (T4-T2)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterWarmup(async, service, bloc);

        int remaining() => (bloc.state as SessionWarmupState).secondsRemaining;
        expect(remaining(), 20);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks(); // ExerciseTick-Event dispatchen
        expect(remaining(), 19);

        // Noch kein Phase-Wechsel, solange das Warm-up läuft.
        expect(service.advancePhaseCallCount, 1); // nur der Countdown
        bloc.close();
      });
    });

    test('bei Timer = 0 wird advancePhase() genau einmal aufgerufen (T4-T3)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterWarmup(async, service, bloc);

        final before = service.advancePhaseCallCount; // 1 (Countdown)

        async.elapse(Duration(seconds: warmupExercise.executionSeconds));
        async.flushMicrotasks();

        expect(service.advancePhaseCallCount, before + 1); // genau einmal
        // Der Warm-up-Zustand bleibt bis zur serverseitigen Bestätigung.
        expect(bloc.state, isA<SessionWarmupState>());
        bloc.close();
      });
    });

    test('Server-Bestätigung PhaseChanged(countdown) nach Warmup → zweiter Countdown (T4-T4)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterWarmup(async, service, bloc);

        async.elapse(Duration(seconds: warmupExercise.executionSeconds));
        async.flushMicrotasks(); // Warm-up = 0 → advancePhase()

        service.emit(
          const PhaseChanged(phase: SessionPhase.countdown, workoutName: 'Ganzkörper-Blitz'),
        );
        async.flushMicrotasks();

        expect(bloc.state, isA<SessionCountdownState>());
        bloc.close();
      });
    });

    test('Server-Bestätigung PhaseChanged(exercise) → Exercise-Zustand (T4-T5)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterWarmup(async, service, bloc);

        async.elapse(Duration(seconds: warmupExercise.executionSeconds));
        async.flushMicrotasks();

        service.emit(
          const PhaseChanged(phase: SessionPhase.exercise, exercise: pushupExercise),
        );
        async.flushMicrotasks();

        final state = bloc.state;
        expect(state, isA<SessionExerciseState>());
        final exercise = state as SessionExerciseState;
        expect(exercise.exercise, pushupExercise);
        expect(exercise.secondsRemaining, pushupExercise.executionSeconds);
        bloc.close();
      });
    });
  });
}
