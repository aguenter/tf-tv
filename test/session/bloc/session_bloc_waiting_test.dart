import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/bloc/session_bloc.dart';
import 'package:tv/session/bloc/session_event.dart';
import 'package:tv/session/bloc/session_state.dart';
import 'package:tv/session/service/session_service.dart';
import '../../helpers/stub_workout_service.dart';

import '../../helpers/scripted_session_service.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('T1 – Warten auf Teilnehmer (Bloc)', () {
    test('legt beim Start eine neue Session an und zeigt T1 (T1-T5)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );

        expect(bloc.state, isA<SessionCreatingState>());
        bloc.add(const SessionStarted());
        async.flushMicrotasks();

        expect(service.createSessionCallCount, 1);
        expect(
          bloc.state,
          isA<SessionWaitingState>()
              .having((s) => s.sessionId, 'sessionId', 'test-session')
              .having((s) => s.participantCount, 'participantCount', 0),
        );
        bloc.close();
      });
    });

    test('Beitritt aktualisiert den Zähler auf T1 (T1-T6)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        bloc.add(const SessionStarted());
        async.flushMicrotasks();

        service.emit(const ParticipantsChanged([trainer]));
        async.flushMicrotasks();

        final state1 = bloc.state as SessionWaitingState;
        expect(state1.participantCount, 1);
        expect(state1.participants, [trainer]);

        service.emit(const ParticipantsChanged([trainer, lena]));
        async.flushMicrotasks();

        final state2 = bloc.state as SessionWaitingState;
        expect(state2.participantCount, 2);
        expect(state2.participants, [trainer, lena]);
        bloc.close();
      });
    });

    test('leere Teilnehmerliste während des Wartens bleibt auf T1 (T1-T7)',
        () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        bloc.add(const SessionStarted());
        async.flushMicrotasks();

        service.emit(const ParticipantsChanged([]));
        async.flushMicrotasks();

        expect(
          bloc.state,
          isA<SessionWaitingState>()
              .having((s) => s.participantCount, 'participantCount', 0),
        );
        bloc.close();
      });
    });

    test('neue Session setzt Zähler zurück (T1-T8)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );

        // Erste Session: Beitritt → Zähler steigt.
        bloc.add(const SessionStarted());
        async.flushMicrotasks();
        service.emit(const ParticipantsChanged([trainer, lena]));
        async.flushMicrotasks();
        expect(
          bloc.state,
          isA<SessionWaitingState>()
              .having((s) => s.participantCount, 'participantCount', 2),
        );

        // Session-Ende → T7 → nach Anzeigedauer neue Session (T1).
        service.emit(const SessionEnded());
        async.flushMicrotasks();
        expect(bloc.state, isA<SessionEndedState>());

        async.elapse(const Duration(seconds: 5)); // T7-Anzeigedauer
        async.flushMicrotasks();

        expect(service.createSessionCallCount, 2);
        expect(
          bloc.state,
          isA<SessionWaitingState>()
              .having((s) => s.participantCount, 'participantCount', 0),
        );
        bloc.close();
      });
    });
  });
}
