import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/bloc/session_bloc.dart';
import 'package:tv/session/bloc/session_event.dart';
import 'package:tv/session/bloc/session_state.dart';
import 'package:tv/session/model/vote.dart';
import 'package:tv/session/service/session_service.dart';
import '../../helpers/stub_workout_service.dart';

import '../../helpers/scripted_session_service.dart';
import '../../helpers/test_fixtures.dart';

/// Bringt den Bloc in den Auswahl-Zustand (T2): Session anlegen,
/// Trainer tritt bei, Trainer startet Auswahl → TV wechselt T1 → T2.
void _enterSelection(FakeAsync async, ScriptedSessionService service, SessionBloc bloc) {
  bloc.add(const SessionStarted());
  async.flushMicrotasks(); // createSession → T1 (Warten)
  service.emit(const ParticipantsChanged([trainer]));
  async.flushMicrotasks(); // Zähler auf 1
  service.emit(const SelectionStarted());
  async.flushMicrotasks(); // _enterSelection: await fetchCatalog() → T2
}

void main() {
  group('T2 – Workout-Auswahl (Bloc)', () {
    test('VotesChanged aktualisiert Stimmen + Trainer-Hervorhebung (T2-T6)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        // P3: Trainer + Lena stimmen für Ganzkörper-Blitz, Jon für Kraft-Fokus.
        service.emit(
          const VotesChanged(votes: votesFixture, trainerWorkoutId: 'ganzkoerper-blitz'),
        );
        async.flushMicrotasks();

        final state = bloc.state;
        expect(state, isA<SessionSelectionState>());
        final selection = state as SessionSelectionState;
        expect(selection.votes, votesFixture);
        expect(selection.trainerWorkoutId, 'ganzkoerper-blitz');
        // Teilnehmerliste bleibt erhalten.
        expect(selection.participants, [trainer]);
        bloc.close();
      });
    });

    test('folgendes VotesChanged ersetzt den Stand (T2-T7)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        // Erstes Voting: Lena für Ganzkörper-Blitz.
        service.emit(
          const VotesChanged(votes: votesFixture, trainerWorkoutId: 'ganzkoerper-blitz'),
        );
        async.flushMicrotasks();

        // Lena wechselt ihre Stimme zu Kraft-Fokus (cast_vote upsert).
        service.emit(
          const VotesChanged(
            votes: [
              Vote(workoutId: 'ganzkoerper-blitz', participantIds: ['p-trainer']),
              Vote(workoutId: 'kraft-fokus', participantIds: ['p-lena', 'p-jon']),
            ],
            trainerWorkoutId: 'ganzkoerper-blitz',
          ),
        );
        async.flushMicrotasks();

        final selection = bloc.state as SessionSelectionState;
        expect(selection.votes, hasLength(2));
        final ganzkoerper = selection.votes.firstWhere((v) => v.workoutId == 'ganzkoerper-blitz');
        final kraft = selection.votes.firstWhere((v) => v.workoutId == 'kraft-fokus');
        expect(ganzkoerper.participantIds, ['p-trainer']); // Lena weg
        expect(kraft.participantIds, ['p-lena', 'p-jon']); // Lena + Jon
        expect(selection.trainerWorkoutId, 'ganzkoerper-blitz'); // bleibt erhalten
        bloc.close();
      });
    });

    test('neue Teilnehmer aktualisieren die Namens-Leiste, Hervorhebung bleibt (T2-T8)',
        () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        _enterSelection(async, service, bloc);

        // Voting steht bereits.
        service.emit(
          const VotesChanged(votes: votesFixture, trainerWorkoutId: 'ganzkoerper-blitz'),
        );
        async.flushMicrotasks();

        // Lena scannt den QR-Code und tritt bei (Presence).
        service.emit(const ParticipantsChanged([trainer, lena]));
        async.flushMicrotasks();

        final selection = bloc.state as SessionSelectionState;
        expect(selection.participants, [trainer, lena]); // Namens-Leiste live
        expect(selection.trainerWorkoutId, 'ganzkoerper-blitz'); // Hervorhebung bleibt
        expect(selection.votes, votesFixture); // Voting-Stand bleibt
        bloc.close();
      });
    });

    test('VotesChanged vor Betreten der Auswahl wird ignoriert (T2-T6, Edge)', () {
      fakeAsync((async) {
        final service = ScriptedSessionService();
        final bloc = SessionBloc(
          sessionService: service,
          workoutService: StubWorkoutService(),
        );
        bloc.add(const SessionStarted());
        async.flushMicrotasks(); // T1 (Warten)

        // Voting kommt, bevor jemand beigetreten ist: TV bleibt auf T1.
        service.emit(
          const VotesChanged(votes: votesFixture, trainerWorkoutId: 'ganzkoerper-blitz'),
        );
        async.flushMicrotasks();

        expect(bloc.state, isA<SessionWaitingState>());
        bloc.close();
      });
    });
  });
}
