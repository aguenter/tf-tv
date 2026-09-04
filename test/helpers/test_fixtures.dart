import 'package:tv/session/model/exercise.dart';
import 'package:tv/session/model/participant.dart';
import 'package:tv/session/model/vote.dart';

/// Geteilte Testdaten für die TV-Test-Suite.
///
/// Gemeinsame Test-Daten für Bloc-, Widget- und Vollablauf-Tests.

// ----------------------------------------------------------------------
// Teilnehmer (Presence)
// ----------------------------------------------------------------------

/// Trainer – tritt als erster bei (erster QR-Scan der Session).
const trainer = Participant(
  id: 'p-trainer',
  displayName: 'Max Mustermann',
  initials: 'MM',
  role: ParticipantRole.trainer,
);

const lena = Participant(
  id: 'p-lena',
  displayName: 'Lena Lorenz',
  initials: 'LL',
  role: ParticipantRole.participant,
);

const jon = Participant(
  id: 'p-jon',
  displayName: 'Jon Jäger',
  initials: 'JJ',
  role: ParticipantRole.participant,
);

/// Alle drei Demo-Teilnehmer (Reihenfolge = Beitrittsreihenfolge).
const allParticipants = [trainer, lena, jon];

// ----------------------------------------------------------------------
// Übungen (Übungs-Pool aus ux/ux.md, Abschnitt 4)
// ----------------------------------------------------------------------

/// Warm-up (fix zuerst, keine Eingabe).
const warmupExercise = Exercise(
  id: 'hampelmann',
  name: 'Jumping Jacks',
  instruction: 'Locker aufwärmen – alle machen mit!',
  executionSeconds: 20,
  inputWindowSeconds: 0,
);

const pushupExercise = Exercise(
  id: 'liegestuetze',
  name: 'Push-ups',
  instruction: 'So viele Liegestütze wie möglich in 40 Sekunden!',
  executionSeconds: 40,
  inputWindowSeconds: 15,
);

const squatExercise = Exercise(
  id: 'kniebeugen',
  name: 'Squats',
  instruction: 'So viele Kniebeugen wie möglich in 40 Sekunden!',
  executionSeconds: 40,
  inputWindowSeconds: 15,
);

const situpExercise = Exercise(
  id: 'situps',
  name: 'Sit-ups',
  instruction: 'So viele Sit-ups wie möglich in 40 Sekunden!',
  executionSeconds: 40,
  inputWindowSeconds: 15,
);

/// Übungs-Pool des Workouts „Ganzkörper-Blitz“ (Reihenfolge aus ux/ux.md):
/// Warm-up, dann Liegestütze → Kniebeugen → Sit-ups.
const ganzkoerperPool = [warmupExercise, pushupExercise, squatExercise, situpExercise];

// ----------------------------------------------------------------------
// Votes (Voting auf T2)
// ----------------------------------------------------------------------

/// Voting-Stand: Trainer + Lena stimmen für „Ganzkörper-Blitz“, Jon für
/// „Kraft-Fokus”.
const votesFixture = [
  Vote(workoutId: 'ganzkoerper-blitz', participantIds: ['p-trainer', 'p-lena']),
  Vote(workoutId: 'kraft-fokus', participantIds: ['p-jon']),
];

/// Workout, das der Trainer ausgewählt hat (Hervorhebung auf T2).
const trainerWorkoutId = 'ganzkoerper-blitz';
