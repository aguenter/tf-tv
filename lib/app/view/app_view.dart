import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../bloc/app_state.dart';
import '../service/supabase_service.dart';
import '../shared/loading_indicator.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc(
        supabaseService: context.read<SupabaseService>(),
      )..add(const AppStarted()),
      child: BlocConsumer<AppBloc, AppState>(
        listener: (context, state) {
          if (state is AppReadyState) {
            context.go('/session');
          }
        },
        builder: (context, state) {
          return const Scaffold(body: LoadingIndicator());
        },
      ),
    );
  }
}
