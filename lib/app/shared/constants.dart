import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Teamfit';

  // Basis des Deep-Links, der als QR-Code auf T1 kodiert wird.
  static const String deepLinkBase = 'https://aguenter.github.io/tf-smartphone';

  /// Deep-Link für eine Session (wird als QR-Code auf T1 kodiert).
  static String deepLinkFor(String sessionId) =>
      '$deepLinkBase/#/join?session=$sessionId';

  // Anzeigedauer des Countdowns (T3) in Sekunden.
  static const int countdownSeconds = 5;

  // Anzeigedauer des Ergebnis-Screens (T6) in Sekunden.
  static const int resultDisplaySeconds = 60;

  // Anzeigedauer des Abschluss-Screens (T7) in Sekunden, danach geht der
  // TV zurück zu T1 und startet eine neue Session.
  static const int endScreenSeconds = 5;

  // Werte kommen aus der .env-Datei (siehe .env.template), geladen via
  // dotenv.load() in main.dart. `.env` selbst ist nicht versioniert.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
