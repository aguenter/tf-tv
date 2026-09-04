import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/bloc/session_bloc.dart';
import 'package:tv/session/bloc/session_event.dart';
import 'package:tv/session/bloc/session_state.dart';
import 'package:tv/session/model/session.dart';
import 'package:tv/session/service/session_service.dart';
import '../../helpers/stub_workout_service.dart';

import '../../helpers/scripted_session_service.dart';
import '../../helpers/test_fixtures.dart';

void _enterSelection(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  bloc.add(const SessionStarted());
  async.flushMicrotasks();
  service.emit(const ParticipantsChanged(allParticipants));
  async.flushMicrotasks();
  service.emit(const SelectionStarted());
  async.flushMicrotasks();
}

void _enterExercise(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  _enterSelection(async, service, bloc);
  service.emit(
    const PhaseChanged(phase: SessionPhase.exercise, exercise: pushupExercise),
  );
  async.flushMicrotasks();
}

void _enterRest(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  _enterExercise(async, service, bloc);
  async.elapse(Duration(seconds: pushupExercise.executionSeconds));
  async.flushMicrotasks();
  service.emit(
    const PhaseChanged(phase: SessionPhase.rest, exercise: pushupExercise),
  );
  async.flushMicrotasks();
}

void main() {
  group('T5 – Exercise (Bloc)', () {
    test('PhaseChanged(exercise) erzeugt Exercise-Zustand mit Timer (T5-T1)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterExercise(async, service, bloc);

        final state = bloc.state;
        expect(state, isA<SessionExerciseState>());
        final exercise = state as SessionExerciseState;
        expect(exercise.exercise, pushupExercise);
        expect(exercise.secondsRemaining, 40);
        bloc.close();
      });
    });

    test('Timer zählt sekündlich 40 → 39 herunter (T5-T2)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterExercise(async, service, bloc);

        int remaining() => (bloc.state as SessionExerciseState).secondsRemaining;
        expect(remaining(), 40);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(remaining(), 39);

        expect(service.advancePhaseCallCount, 0);
        bloc.close();
      });
    });

    test('bei Timer = 0 wird advancePhase() aufgerufen (T5-T3)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterExercise(async, service, bloc);

        async.elapse(Duration(seconds: pushupExercise.executionSeconds));
        async.flushMicrotasks();

        expect(service.advancePhaseCallCount, 1);
        bloc.close();
      });
    });
  });

  group('T5b – Rest (Bloc)', () {
    test('PhaseChanged(rest) erzeugt Rest-Zustand mit inputWindowSeconds (T5b-T1)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterRest(async, service, bloc);

        final state = bloc.state;
        expect(state, isA<SessionRestState>());
        final rest = state as SessionRestState;
        expect(rest.exercise, pushupExercise);
        expect(rest.secondsRemaining, pushupExercise.inputWindowSeconds);
        expect(rest.participants, allParticipants);
        expect(rest.submittedParticipantIds, isEmpty);
        bloc.close();
      });
    });

    test('ResultSubmitted → Häkchen für genau diese Person (T5b-T2)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterRest(async, service, bloc);

        service.emit(const ResultSubmitted(participant: lena, value: 12));
        async.flushMicrotasks();

        final state = bloc.state as SessionRestState;
        expect(state.submittedParticipantIds, {'p-lena'});
        expect(service.advancePhaseCallCount, 1); // only exercise advance
        bloc.close();
      });
    });

    test('alle eingetragen → advancePhase() (T5b-T3)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterRest(async, service, bloc);
        final before = service.advancePhaseCallCount;

        service.emit(const ResultSubmitted(participant: trainer, value: 8));
        async.flushMicrotasks();
        service.emit(const ResultSubmitted(participant: lena, value: 12));
        async.flushMicrotasks();
        service.emit(const ResultSubmitted(participant: jon, value: 5));
        async.flushMicrotasks();

        expect(service.advancePhaseCallCount, before + 1);
        bloc.close();
      });
    });

    test('Rest-Timer Timeout → advancePhase() als Fallback (T5b-T4)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterRest(async, service, bloc);
        final before = service.advancePhaseCallCount;

        service.emit(const ResultSubmitted(participant: lena, value: 12));
        async.flushMicrotasks();

        async.elapse(Duration(seconds: pushupExercise.inputWindowSeconds));
        async.flushMicrotasks();

        expect(service.advancePhaseCallCount, before + 1);
        bloc.close();
      });
    });
  });
}
