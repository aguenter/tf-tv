@Tags(['integration'])
library;

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

/// Integration tests for T1→T2 transition: TV receives Postgres Changes
/// when the trainer calls start_selection.
///
/// Run with: flutter test test/integration/t2_selection_transition_test.dart

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

  group('T1→T2 – Selection transition (TV)', () {
    test('Postgres Changes notifies TV when trainer starts selection',
        () async {
      final sessionId = await _tv.rpc<String>('create_session');

      // Trainer joins.
      await _phone.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      // TV subscribes to session changes.
      final completer = Completer<Map<String, dynamic>>();
      final channel = _tv.channel('test-transition-$sessionId');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'sessions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: sessionId,
        ),
        callback: (payload) {
          if (!completer.isCompleted) {
            completer.complete(payload.newRecord);
          }
        },
      );
      channel.subscribe();

      // Trainer starts selection.
      await _phone.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });

      final record = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'No Postgres Changes event received within 10 seconds',
        ),
      );

      expect(record['status'], 'selecting');
      await _tv.removeChannel(channel);
    });

    test('session row has status selecting after start_selection', () async {
      final sessionId = await _tv.rpc<String>('create_session');

      await _phone.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      await _phone.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });

      final rows = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .limit(1);

      expect(rows.length, 1);
      expect(rows.first['status'], 'selecting');
    });

    test('start_selection is idempotent (calling twice does not error)',
        () async {
      final sessionId = await _tv.rpc<String>('create_session');

      await _phone.rpc('join_session', params: {
        'p_session_id': sessionId,
        'p_display_name': 'Anna',
      });

      await _phone.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });

      // Second call should not throw.
      await _phone.rpc('start_selection', params: {
        'p_session_id': sessionId,
      });

      final rows = await _tv
          .from('sessions')
          .select()
          .eq('id', sessionId)
          .limit(1);

      expect(rows.first['status'], 'selecting');
    });
  });
}
