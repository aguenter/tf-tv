import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:supabase/supabase.dart' hide Session;

import '../../app/shared/lifecycle_reporter.dart';
import '../../app/shared/loading_indicator.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart';
import '../service/session_service.dart';
import '../service/workout_service.dart';
import 't1_start_view.dart';
import 't2_selection_view.dart';
import 't3_countdown_view.dart';
import 't4_warmup_view.dart';
import 't5_exercise_view.dart';
import 't5b_rest_view.dart';
import 't6_result_view.dart';
import 't7_end_view.dart';

class SessionView extends StatelessWidget {
  const SessionView({
    super.key,
    required this.sessionService,
    required this.supabaseClient,
  });

  final SessionService sessionService;
  final SupabaseClient supabaseClient;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final workoutService = WorkoutService(client: supabaseClient);
        return SessionBloc(
          sessionService: sessionService,
          workoutService: workoutService,
        )..add(const SessionStarted());
      },
      // Builder, damit der Kontext unterhalb des BlocProvider liegt und den
      // SessionBloc lesen kann; LifecycleReporter stößt beim Wiedererscheinen
      // die sofortige Restzeit-Neuberechnung an.
      child: Builder(
        builder: (context) => LifecycleReporter(
          onResume: () =>
              context.read<SessionBloc>().add(const LifecycleResumed()),
          child: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              return Scaffold(
                body: switch (state) {
                  SessionCreatingState() => const LoadingIndicator(),
                  SessionWaitingState(:final sessionId, :final participants) =>
                    T1StartView(
                      sessionId: sessionId,
                      participants: participants,
                    ),
                  SessionSelectionState(
                    :final workouts,
                    :final votes,
                    :final participants,
                    :final trainerWorkoutId,
                  ) =>
                    T2SelectionView(
                      workouts: workouts,
                      votes: votes,
                      participants: participants,
                      trainerWorkoutId: trainerWorkoutId,
                    ),
                  SessionCountdownState(
                    :final workoutName,
                    :final secondsRemaining,
                  ) =>
                    T3CountdownView(
                      workoutName: workoutName,
                      secondsRemaining: secondsRemaining,
                    ),
                  SessionWarmupState(
                    :final exercise,
                    :final secondsRemaining,
                  ) =>
                    T4WarmupView(
                      exercise: exercise,
                      secondsRemaining: secondsRemaining,
                    ),
                  SessionExerciseState(
                    :final exercise,
                    :final secondsRemaining,
                  ) =>
                    T5ExerciseView(
                      exercise: exercise,
                      secondsRemaining: secondsRemaining,
                    ),
                  SessionRestState(
                    :final exercise,
                    :final secondsRemaining,
                    :final totalSeconds,
                    :final participants,
                    :final submittedParticipantIds,
                  ) =>
                    T5bRestView(
                      exercise: exercise,
                      secondsRemaining: secondsRemaining,
                      totalSeconds: totalSeconds,
                      participants: participants,
                      submittedParticipantIds: submittedParticipantIds,
                    ),
                  SessionResultState(
                    :final participants,
                    :final teamTotal,
                    :final exerciseResults,
                  ) =>
                    T6ResultView(
                      participants: participants,
                      teamTotal: teamTotal,
                      exerciseResults: exerciseResults,
                    ),
                  SessionEndedState() => const T7EndView(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
