import 'package:flutter/material.dart';

import '../../app/shared/theme.dart';
import '../model/participant.dart';
import '../model/result.dart';
import '../widget/initials_badge.dart';

/// T6 – Ergebnis-Screen.
///
/// Zwei Balken-Diagramme, jeweils **ein Balken pro Übung**:
///  1. Team-Leistung – Summe aller Teilnehmer je Übung.
///  2. Einzel-Bestleistung – nur die/der Beste je Übung, gezeigt als
///     Initialen-Badge (keine vollen Namen). Bei Gleichstand gewinnt, wer
///     zuerst eingetragen hat (siehe [ChallengeResults.aggregate]).
class T6ResultView extends StatelessWidget {
  const T6ResultView({
    super.key,
    required this.participants,
    required this.teamTotal,
    required this.exerciseResults,
  });

  final List<Participant> participants;
  final int teamTotal;
  final List<ExerciseResult> exerciseResults;

  @override
  Widget build(BuildContext context) {
    final participantsById = {
      for (final participant in participants) participant.id: participant,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TeamfitSpacing.s12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(teamTotal: teamTotal),
              const SizedBox(height: TeamfitSpacing.s12),
              _TeamPerExercise(exerciseResults: exerciseResults),
              const SizedBox(height: TeamfitSpacing.s10),
              _TopPerExercise(
                exerciseResults: exerciseResults,
                participantsById: participantsById,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// „TEAM RESULT“ + große Team-Gesamtsumme.
class _Header extends StatelessWidget {
  const _Header({required this.teamTotal});

  final int teamTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TEAM RESULT',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: TeamfitSpacing.s1),
        Text(
          '$teamTotal',
          style: TeamfitTypo.mono(
            fontSize: 72,
            color: TeamfitColors.brand,
          ),
        ),
        Text(
          'REPS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TeamfitColors.brand,
              ),
        ),
      ],
    );
  }
}

/// Diagramm 1 – Team-Leistung je Übung (ein Balken pro Übung).
class _TeamPerExercise extends StatelessWidget {
  const _TeamPerExercise({required this.exerciseResults});

  final List<ExerciseResult> exerciseResults;

  @override
  Widget build(BuildContext context) {
    var max = 0;
    for (final result in exerciseResults) {
      if (result.teamTotal > max) max = result.teamTotal;
    }

    return _Section(
      label: 'TEAM PER EXERCISE',
      children: [
        for (final result in exerciseResults)
          _BarRow(
            title: result.exercise.name,
            value: result.teamTotal,
            fraction: max > 0 ? result.teamTotal / max : 0,
            color: TeamfitColors.brand,
          ),
      ],
    );
  }
}

/// Diagramm 2 – Einzel-Bestleistung je Übung (nur Badge, keine Namen).
class _TopPerExercise extends StatelessWidget {
  const _TopPerExercise({
    required this.exerciseResults,
    required this.participantsById,
  });

  final List<ExerciseResult> exerciseResults;
  final Map<String, Participant> participantsById;

  @override
  Widget build(BuildContext context) {
    var max = 0;
    for (final result in exerciseResults) {
      if (result.topValue > max) max = result.topValue;
    }

    return _Section(
      label: 'TOP PER EXERCISE',
      children: [
        for (final result in exerciseResults)
          _BarRow(
            title: result.exercise.name,
            value: result.topValue,
            fraction: max > 0 ? result.topValue / max : 0,
            color: TeamfitColors.streak500,
            leadingBadge:
                _badgeFor(participantsById[result.topParticipantId]),
          ),
      ],
    );
  }

  Widget _badgeFor(Participant? participant) {
    if (participant == null) {
      // Keine Eingabe für diese Übung.
      return const InitialsBadge(initials: '–', size: 40);
    }
    return InitialsBadge(
      initials: participant.initials,
      isTrainer: participant.role == ParticipantRole.trainer,
      size: 40,
    );
  }
}

/// Abschnitt mit Eyebrow-Label und einer Balken-Liste.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TeamfitColors.textOnInverseMuted,
              ),
        ),
        const SizedBox(height: TeamfitSpacing.s4),
        for (final child in children) ...[
          child,
          const SizedBox(height: TeamfitSpacing.s3),
        ],
      ],
    );
  }
}

/// Ein Balken: (optionales Badge) + Übungsname + Balken + Wert.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.title,
    required this.value,
    required this.fraction,
    required this.color,
    this.leadingBadge,
  });

  final String title;
  final int value;
  final double fraction;
  final Color color;
  final Widget? leadingBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Feste Badge-Spalte in jeder Zeile – so beginnen alle Balken (in
        // beiden Diagrammen) an derselben linken Kante. Team-Zeilen ohne
        // Badge lassen den Platz leer.
        SizedBox(
          width: 40,
          child: leadingBadge != null
              ? Align(alignment: Alignment.centerLeft, child: leadingBadge)
              : null,
        ),
        const SizedBox(width: TeamfitSpacing.s3),
        SizedBox(
          width: 180,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TeamfitSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 24,
              backgroundColor: TeamfitColors.ink700,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TeamfitTypo.mono(fontSize: 22, color: color),
          ),
        ),
      ],
    );
  }
}
