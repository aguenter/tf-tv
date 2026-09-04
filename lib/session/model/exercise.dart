import 'package:equatable/equatable.dart';

enum MetricType { reps, seconds }

/// Eine Übung aus dem Übungs-Pool (exercises-Tabelle, siehe
/// doc/1-Backend-Realtime.md, Abschnitt 2).
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.executionSeconds,
    required this.inputWindowSeconds,
    this.metricType = MetricType.reps,
    this.imagePath,
  });

  factory Exercise.fromRow(Map<String, dynamic> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      instruction: (row['instruction'] as String?) ?? '',
      executionSeconds: row['execution_seconds'] as int,
      inputWindowSeconds: row['input_window_seconds'] as int,
      metricType: (row['metric_type'] as String?) == 'seconds'
          ? MetricType.seconds
          : MetricType.reps,
      imagePath: row['image_path'] as String?,
    );
  }

  final String id;
  final String name;

  /// Kurzanleitung, die groß auf dem TV angezeigt wird (T4/T5).
  final String instruction;

  /// Ausführungsdauer in Sekunden (Timer auf dem TV).
  final int executionSeconds;

  /// Eingabe-Fenster für die Smartphones in Sekunden (0 = keine Eingabe,
  /// z. B. Warm-up).
  final int inputWindowSeconds;

  final MetricType metricType;

  /// Storage-Pfad des Übungsbildes (z. B. 'app_assets/placeholder.webp').
  final String? imagePath;

  @override
  List<Object?> get props =>
      [id, name, instruction, executionSeconds, inputWindowSeconds, metricType, imagePath];
}
