import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/service/supabase_service.dart';
import 'app/shared/constants.dart';
import 'app/shared/router.dart';
import 'app/shared/theme.dart';
import 'app/shared/wakelock_guard.dart';
import 'session/service/session_service.dart';
import 'session/service/supabase_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseService = SupabaseService(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Anonymous auth gives the TV a stable identity for Realtime channels.
  await supabaseService.client.auth.signInAnonymously();

  final sessionService = SupabaseSessionService(client: supabaseService.client);

  runApp(
    TeamfitTvApp(
      supabaseService: supabaseService,
      sessionService: sessionService,
    ),
  );
}

class TeamfitTvApp extends StatelessWidget {
  const TeamfitTvApp({
    super.key,
    required this.supabaseService,
    required this.sessionService,
  });

  final SupabaseService supabaseService;
  final SessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SupabaseService>.value(value: supabaseService),
        RepositoryProvider<SessionService>.value(value: sessionService),
      ],
      child: WakelockGuard(
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: TeamfitTheme.dark(),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
