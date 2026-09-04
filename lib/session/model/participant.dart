import 'package:equatable/equatable.dart';

/// Rolle eines Teilnehmers innerhalb einer Session (participants.role).
enum ParticipantRole { trainer, participant }

/// Ein Gerät/eine Person innerhalb einer Session (participants-Tabelle).
class Participant extends Equatable {
  const Participant({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.role,
  });

  final String id;
  final String displayName;

  /// Initialen für die TV-Anzeige (z. B. "MM"), abgeleitet aus dem
  /// Anzeigenamen.
  final String initials;
  final ParticipantRole role;

  @override
  List<Object?> get props => [id, displayName, initials, role];
}
