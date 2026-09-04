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

/// Bringt den Bloc in den Auswahl-Zustand (T2) mit allen drei
/// Demo-Teilnehmer:innen.
void _enterSelection(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  bloc.add(const SessionStarted());
  async.flushMicrotasks(); // createSession → T1 (Warten)
  service.emit(const ParticipantsChanged(allParticipants));
  async.flushMicrotasks(); // Zähler aktualisiert
  service.emit(const SelectionStarted());
  async.flushMicrotasks(); // → T2 (Auswahl)
}

/// Bringt den Bloc in den Rest-Zustand (T5b).
void _enterRest(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  _enterSelection(async, service, bloc);
  service.emit(
    const PhaseChanged(phase: SessionPhase.rest, exercise: pushupExercise),
  );
  async.flushMicrotasks();
}

/// Lässt alle drei Ergebnisse eintreffen (→ advancePhase, da alle eingetragen).
void _completeRest(FakeAsync async, ScriptedSessionService service) {
  service.emit(const ResultSubmitted(participant: trainer, value: 8));
  async.flushMicrotasks();
  service.emit(const ResultSubmitted(participant: lena, value: 12));
  async.flushMicrotasks();
  service.emit(const ResultSubmitted(participant: jon, value: 5));
  async.flushMicrotasks();
}

/// Bringt den Bloc in den Ergebnis-Zustand (T6).
void _enterResult(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  _enterRest(async, service, bloc);
  _completeRest(async, service);
  service.emit(const PhaseChanged(phase: SessionPhase.result));
  async.flushMicrotasks();
}

void main() {
  group('T6 – Ergebnis (Bloc)', () {
    test(
        'PhaseChanged(result) → Ergebnis-Zustand mit Aggregation je Teilnehmer + Team-Summe (T6-T1)',
        () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterResult(async, service, bloc);

        final state = bloc.state;
        expect(state, isA<SessionResultState>());
        final result = state as SessionResultState;
        expect(result.participants, allParticipants);
        expect(
          result.resultsByParticipant,
          {'p-trainer': 8, 'p-lena': 12, 'p-jon': 5},
        );
        expect(result.teamTotal, 25); // 8 + 12 + 5

        // Ein Aggregat für die eine Challenge-Übung (Liegestütze).
        expect(result.exerciseResults, hasLength(1));
        final pushups = result.exerciseResults.single;
        expect(pushups.exercise, pushupExercise);
        expect(pushups.teamTotal, 25);
        expect(pushups.topParticipantId, 'p-lena'); // 12 = Bestwert
        expect(pushups.topValue, 12);
        bloc.close();
      });
    });

    test('nach 10 s Anzeigedauer wird endSession() genau einmal aufgerufen (T6-T2)',
        () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterResult(async, service, bloc);

        async.elapse(const Duration(seconds: AppConstants.resultDisplaySeconds));
        async.flushMicrotasks();

        expect(service.endSessionCallCount, 1); // genau einmal
        bloc.close();
      });
    });

    test('Teilnehmer ohne Eingabe werden mit 0 angezeigt (Edge Case, T6-T3)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterRest(async, service, bloc);

        // Nur Lena trägt ein; der Rest-Timeout schaltet weiter.
        service.emit(const ResultSubmitted(participant: lena, value: 12));
        async.flushMicrotasks();
        async.elapse(Duration(seconds: pushupExercise.inputWindowSeconds));
        async.flushMicrotasks(); // Timeout → advancePhase()

        service.emit(const PhaseChanged(phase: SessionPhase.result));
        async.flushMicrotasks(); // → T6 (Ergebnis)

        final state = bloc.state as SessionResultState;
        expect(state.resultsByParticipant['p-lena'], 12);
        // Max und Jon haben nichts eingetragen → 0.
        expect(state.resultsByParticipant['p-trainer'] ?? 0, 0);
        expect(state.resultsByParticipant['p-jon'] ?? 0, 0);
        expect(state.teamTotal, 12);
        bloc.close();
      });
    });
  });

  group('T7 – Abschluss (Bloc)', () {
    test('SessionEnded-Update → Abschluss-Zustand (T7-T1)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterResult(async, service, bloc);

        // T6-Anzeigedauer ablaufen → endSession() → Server bestätigt.
        async.elapse(const Duration(seconds: AppConstants.resultDisplaySeconds));
        async.flushMicrotasks();
        expect(service.endSessionCallCount, 1);

        service.emit(const SessionEnded());
        async.flushMicrotasks();

        expect(bloc.state, isA<SessionEndedState>());
        bloc.close();
      });
    });

    test('nach 5 s wird eine neue Session angelegt (zurück zu T1, T7-T2)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterResult(async, service, bloc);

        async.elapse(const Duration(seconds: AppConstants.resultDisplaySeconds));
        async.flushMicrotasks(); // endSession()
        service.emit(const SessionEnded());
        async.flushMicrotasks(); // → T7 (Abschluss)

        expect(bloc.state, isA<SessionEndedState>());
        final createCallsBefore = service.createSessionCallCount; // 1 (Anfang)

        async.elapse(const Duration(seconds: AppConstants.endScreenSeconds));
        async.flushMicrotasks();

        // Neue Session → zurück zu T1 (Warten, 0 Teilnehmer).
        expect(service.createSessionCallCount, createCallsBefore + 1);
        final state = bloc.state;
        expect(state, isA<SessionWaitingState>());
        expect((state as SessionWaitingState).participantCount, 0);
        bloc.close();
      });
    });
  });
}
