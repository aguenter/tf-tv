import 'dart:async';

import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/session.dart';
import '../model/vote.dart';

/// Updates, die der Service an den Bloc emittiert.
///
/// In Produktion kommen sie aus Supabase Realtime (Presence + Postgres
/// Changes) auf dem Channel `session:<id>`; im Demo-Modus stammen sie aus
/// der lokalen Simulation (siehe `simulated_session_service.dart`).
abstract class SessionUpdate {
  const SessionUpdate();
}

/// Teilnehmer:innen sind beigetreten oder ausgetreten (Presence).
class ParticipantsChanged extends SessionUpdate {
  const ParticipantsChanged(this.participants);

  final List<Participant> participants;
}

/// Der Voting-Stand hat sich geändert (Postgres Changes auf votes).
class VotesChanged extends SessionUpdate {
  const VotesChanged({required this.votes, required this.trainerWorkoutId});

  final List<Vote> votes;

  /// Workout, das der Trainer ausgewählt hat (Hervorhebung auf T2).
  final String? trainerWorkoutId;
}

/// Die Session-Phase hat sich geändert (Postgres Changes auf sessions).
class PhaseChanged extends SessionUpdate {
  const PhaseChanged({
    required this.phase,
    this.workoutName,
    this.exercise,
  });

  final SessionPhase phase;
  final String? workoutName;

  /// Bei warmup/challenge: die anzuzeigende Übung.
  final Exercise? exercise;
}

/// Ein Ergebnis wurde eingetragen (Postgres Changes auf results).
class ResultSubmitted extends SessionUpdate {
  const ResultSubmitted({required this.participant, required this.value});

  final Participant participant;
  final int value;
}

/// Der Trainer hat die Auswahl gestartet (T1 → T2).
class SelectionStarted extends SessionUpdate {
  const SelectionStarted();
}

/// Die Session wurde beendet (sessions.status = 'ended').
class SessionEnded extends SessionUpdate {
  const SessionEnded();
}

/// Schnittstelle zum Session-Backend (siehe doc/1-Backend-Realtime.md).
///
/// Der Bloc kommuniziert ausschließlich über diese Schnittstelle:
/// - RPC-Aufrufe ([createSession], [advancePhase], [endSession]) für
///   Zustandsänderungen, die serverseitig Geschäftsregeln durchsetzen.
/// - [updates]-Stream für alle eingehenden Realtime-Updates (Presence,
///   Postgres Changes) – in Produktion vom Channel `session:<id>`.
///
/// Implementierungen:
/// - `SupabaseSessionService`: Supabase Realtime + RPCs (Produktion).
/// - `ScriptedSessionService`: deterministisches Test-Doppel (test/).
abstract class SessionService {
  /// Legt eine neue Session an (T1) und tritt dem Channel bei.
  Future<Session> createSession();

  /// Schaltet die Phase weiter (wird vom Bloc als Session-Treiber bei
  /// Ablauf einer Phase aufgerufen).
  Future<void> advancePhase();

  /// Beendet die Session (nach T6/T7).
  Future<void> endSession();

  /// Updates für den Bloc (Presence, Postgres Changes).
  Stream<SessionUpdate> get updates;

  /// Aktuelle Session (z. B. für den QR-Code auf T1).
  Session? get session;

  /// Räumt Timer und Abonnements auf.
  void dispose();
}
