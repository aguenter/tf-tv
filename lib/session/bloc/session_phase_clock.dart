import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart' show Bloc;

import '../service/session_service.dart';
import 'session_event.dart';
import 'session_state.dart';

/// Timer-Treiber für die Session-Phasen (T3–T7).
///
/// Der [SessionBloc] ist ein reiner Event→Zustand-Mapper und besitzt selbst
/// keine Timer. Diese Klasse hält den Phasen-Timer (1-s-Tick) und die
/// Einmal-Timer und übersetzt deren Ablauf in Events ([CountdownTick],
/// [ExerciseTick]) bzw. Service-Aufrufe (`advancePhase`, `endSession`).
///
/// **Warum Events?** In bloc 9.x darf der Handler-`Emitter` nur während des
/// laufenden Event-Handlers verwendet werden. Timer-Callbacks feuern nach
/// dessen Abschluss und dürfen daher nicht direkt Zustand emittieren, sondern
/// reihen Tick-Events in die Warteschlange ein.
class SessionPhaseClock {
  SessionPhaseClock(this._bloc, this._sessionService);

  /// Bloc, der die Tick-Events empfängt (es wird nur `add` verwendet).
  final Bloc<SessionEvent, SessionState> _bloc;

  /// Backend für Phasenübergänge (`advancePhase`, `endSession`).
  final SessionService _sessionService;

  Timer? _phaseTimer;
  Timer? _inputTimeoutTimer;

  /// Einmal-Timer für das Phase-Ende (T6 → `endSession`, T7 → neue
  /// Session). Bewusst nicht der periodische Phasen-Tick: Die Anzeigedauer
  /// endet genau einmal, und bei einer frühen Server-Bestätigung
  /// (`SessionEnded`) muss der Timer via [cancelAll] abgebrochen werden –
  /// ein periodischer Timer würde `endSession()` sonst jede Sekunde erneut
  /// aufrufen.
  Timer? _phaseEndTimer;

  /// Startet den 1-s-Tick für den Countdown (T3).
  void startCountdown() {
    _restartPhaseTimer(() => _bloc.add(const CountdownTick()));
  }

  /// Startet den 1-s-Tick für eine Übungs-Phase (T4/T5).
  void startExercise() {
    _restartPhaseTimer(() => _bloc.add(const ExerciseTick()));
  }

  /// Stoppt den Phasen-Timer (Phase beendet oder neue Phase).
  void stopPhaseTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
  }

  /// Einmalig: `advancePhase()` nach [seconds] (Eingabe-Fenster-Timeout, T5).
  void armInputTimeout(int seconds) {
    _inputTimeoutTimer?.cancel();
    _inputTimeoutTimer = Timer(
      Duration(seconds: seconds),
      () => unawaited(_sessionService.advancePhase()),
    );
  }

  /// Rüstet den Eingabe-Fenster-Timeout ab (alle haben eingetragen).
  void disarmInputTimeout() {
    _inputTimeoutTimer?.cancel();
    _inputTimeoutTimer = null;
  }

  /// Einmalig: `endSession()` nach [seconds] (T6-Anzeigedauer).
  void armEndAfter(int seconds) {
    _phaseEndTimer?.cancel();
    _phaseEndTimer = Timer(
      Duration(seconds: seconds),
      () => unawaited(_sessionService.endSession()),
    );
  }

  /// Einmalig: neue Session (T1) nach [seconds] (T7-Anzeigedauer).
  void armNewSessionAfter(int seconds) {
    _phaseEndTimer?.cancel();
    _phaseEndTimer = Timer(
      Duration(seconds: seconds),
      () => _bloc.add(const SessionStarted()),
    );
  }

  /// Rüstet alle Timer ab (Phasenwechsel, Close).
  void cancelAll() {
    stopPhaseTimer();
    disarmInputTimeout();
    _phaseEndTimer?.cancel();
    _phaseEndTimer = null;
  }

  void _restartPhaseTimer(void Function() onFire) {
    stopPhaseTimer();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (_) => onFire());
  }
}
