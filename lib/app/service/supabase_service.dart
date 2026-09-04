import 'package:supabase/supabase.dart';

/// Stellt die Verbindung zu Supabase her (Datenbank, Realtime, Auth) und
/// wird von den Features als gemeinsame Datendrehscheibe zur
/// Smartphone-WebApp genutzt.
class SupabaseService {
  SupabaseService({required String url, required String anonKey})
      : client = SupabaseClient(url, anonKey);

  final SupabaseClient client;

  Future<void> connect() async {
    // TODO: Realtime-Channels, Auth-Konzept und Sicherheitsregeln folgen in
    // einem separaten Schritt (siehe doc/0-Architecture.md).
  }
}
