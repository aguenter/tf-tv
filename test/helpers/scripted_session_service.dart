import 'dart:async';

import 'package:tv/session/model/session.dart';
import 'package:tv/session/service/session_service.dart';

/// Test-Doppel für [SessionService]: emuliert das Backend deterministisch.
///
/// - RPC-Aufrufe werden nur protokolliert ([createSessionCallCount],
///   [advancePhaseCallCount], [endSessionCallCount]) – der Test kann sie
///   als Assertions verwenden.
/// - Updates (Smartphone-Events wie Beitritt/Voting/Ergebnis sowie
///   Server-Bestätigungen wie Phasenwechsel) emittiert der Test gezielt
///   über [emit] – volle Kontrolle über Timing und Reihenfolge.
class ScriptedSessionService extends SessionService {
  final StreamController<SessionUpdate> _controller =
      StreamController<SessionUpdate>.broadcast();

  Session? _session;

  int createSessionCallCount = 0;
  int advancePhaseCallCount = 0;
  int endSessionCallCount = 0;

  @override
  Future<Session> createSession() async {
    createSessionCallCount++;
    _session = Session(id: 'test-session', status: SessionStatus.waiting);
    return _session!;
  }

  @override
  Future<void> advancePhase() async {
    advancePhaseCallCount++;
  }

  @override
  Future<void> endSession() async {
    endSessionCallCount++;
    _session = _session?.copyWith(status: SessionStatus.ended);
  }

  @override
  Stream<SessionUpdate> get updates => _controller.stream;

  @override
  Session? get session => _session;

  /// Emittiert ein Update (simuliertes Smartphone-Event bzw.
  /// serverseitige Bestätigung).
  void emit(SessionUpdate update) {
    if (!_controller.isClosed) {
      _controller.add(update);
    }
  }

  @override
  void dispose() {
    _session = null;
    _controller.close();
  }
}
