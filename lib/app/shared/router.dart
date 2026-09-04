import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../session/service/session_service.dart';
import '../../session/view/session_view.dart';
import '../service/supabase_service.dart';
import '../view/app_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppView(),
    ),
    GoRoute(
      path: '/session',
      builder: (context, state) => SessionView(
        sessionService: context.read<SessionService>(),
        supabaseClient: context.read<SupabaseService>().client,
      ),
    ),
  ],
);
