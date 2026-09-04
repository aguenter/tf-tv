import 'package:flutter_test/flutter_test.dart';

import 'package:tv/app/bloc/app_bloc.dart';
import 'package:tv/app/bloc/app_event.dart';
import 'package:tv/app/bloc/app_state.dart';
import 'package:tv/app/service/supabase_service.dart';

/// Unit-Tests für den App-Bloc (Loading → Ready).
///
/// [SupabaseService.connect] ist im Skeleton ein No-Op (TODO: Realtime,
/// Auth), daher reicht der echte Service – kein Test-Doppel nötig.

void main() {
  SupabaseService testService() => SupabaseService(
        url: 'https://example.supabase.co',
        anonKey: 'test-key',
      );

  group('AppBloc', () {
    test('Initialzustand ist Loading (Session-Screen noch nicht sichtbar)',
        () {
      final bloc = AppBloc(supabaseService: testService());
      expect(bloc.state, const AppLoadingState());
      bloc.close();
    });

    test('AppStarted → Verbindung aufgebaut → Ready', () async {
      final bloc = AppBloc(supabaseService: testService());
      bloc.add(const AppStarted());
      await expectLater(bloc.stream, emitsInOrder([const AppReadyState()]));
      bloc.close();
    });
  });
}
