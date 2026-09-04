import 'package:equatable/equatable.dart';

import '../service/session_service.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Wird beim Betreten des Session-Features ausgelöst und legt eine neue
/// Session an (T1).
class SessionStarted extends SessionEvent {
  const SessionStarted();
}

/// Reiht ein Update des [SessionService] (in Produktion: Supabase Realtime)
/// in die Event-Warteschlange ein, damit alle Zustandsänderungen in
/// Event-Handler stattfinden.
class SessionUpdateReceived extends SessionEvent {
  const SessionUpdateReceived(this.update);

  final SessionUpdate update;

  @override
  List<Object?> get props => [update];
}

/// Ein Sekunden-Tick der Countdown-Phase (T3). Wird vom Phasen-Timer
/// eingereiht; der Handler zählt [SessionCountdownState.secondsRemaining]
/// herunter und ruft bei 0 `advancePhase()` auf.
class CountdownTick extends SessionEvent {
  const CountdownTick();
}

/// Ein Sekunden-Tick einer Übungs-Phase (T4 Warm-up / T5 Challenge).
/// Wird vom Phasen-Timer eingereiht; der Handler zählt die Restzeit herunter.
/// Bei Challenges öffnet er bei 0 das Eingabe-Fenster (mit Timeout-Fallback).
class ExerciseTick extends SessionEvent {
  const ExerciseTick();
}
