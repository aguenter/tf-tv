@Tags(['integration'])
library;

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for T1: TV creates a session and receives participant
/// updates via Postgres Changes when smartphones join.
///
/// These tests hit a real Supabase instance (local via `supabase start` or a
/// test project). Set SUPABASE_URL and SUPABASE_ANON_KEY in the .env file.
///
/// Run with: flutter test test/integration/t1_create_session_test.dart

late SupabaseClient _tv;
late SupabaseClient _phone;

Future<SupabaseClient> _createClient() async {
  final url = dotenv.get('SUPABASE_URL');
  final key = dotenv.get('SUPABASE_ANON_KEY');
  final client = SupabaseClient(url, key);
  await client.auth.signInAnonymously();
  return client;
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    _tv = await _createClient();
    _phone = await _createClient();
  });

  tearDownAll(() {
    _tv.dispose();
    _phone.dispose();
  });

  group('T1 – Create Session (TV)', () {
    test('create_session returns a valid UUID with status waiting', () async {
      final sessionId = await _tv.rpc<String>('create_session');

      expect(sessionId, isNotEmpty);

      final rows = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .limit(1);

      expect(rows.length, 1);
      expect(rows.first['status'], 'waiting');
      expect(rows.first['trainer_participant_id'], isNull);
      expect(rows.first['phase'], isNull);
    });

    test('two create_session calls produce different IDs', () async {
      final id1 = await _tv.rpc<String>('create_session');
      final id2 = await _tv.rpc<String>('create_session');

      expect(id1, isNot(equals(id2)));
    });

    test('Postgres Changes notifies TV when a participant joins', () async {
      final sessionId = await _tv.rpc<String>('create_session');

      final completer = Completer<Map<String, dynamic>>();

      // Subscribe to Postgres Changes on participants.
      final channel = _tv.channel('test-session-$sessionId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'participants',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'session_id',
          value: sessionId,
        ),
        callback: (payload) {
          if (!completer.isCompleted) {
            completer.complete(payload.newRecord);
          }
        },
      );
      channel.subscribe();

      // Smartphone joins.
      await _phone.rpc(
        'join_session',
        params: {
          'p_session_id': sessionId,
          'p_display_name': 'TestUser',
        },
      );

      final record = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'No Postgres Changes event received within 10 seconds',
        ),
      );

      expect(record['display_name'], 'TestUser');
      expect(record['session_id'], sessionId);
      expect(record['role'], isNotNull);

      await _tv.removeChannel(channel);
    });
  });
}
