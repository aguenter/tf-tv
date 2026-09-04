#!/usr/bin/env dart
/// Standalone script to verify exercise image URLs in Supabase Storage.
///
/// Run from the tv directory:
///   cd src/tv && dart test/session/widget/verify_image_urls.dart
import 'dart:io';

const imagePaths = {
  'jumping_jack': 'app_assets/jumping_jack_anim.webp',
  'pushup': 'app_assets/pushup_anim.webp',
  'squat': 'app_assets/squat_anim.webp',
  'situp': 'app_assets/situp_anim.webp',
  'arm_circle': 'app_assets/armcircles_static.webp',
  'lunge': 'app_assets/lunge_anim.webp',
  'plank': 'app_assets/plank_static.webp',
  'torso_twist': 'app_assets/torsotwist_anim.webp',
  'mountain_climber': 'app_assets/mountainclimber_anim.webp',
  'bicycle_crunch': 'app_assets/bycycle_crunches_anim.webp',
};

Future<void> main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('ERROR: .env file not found. Run from src/tv/.');
    exit(1);
  }

  var supabaseUrl = '';
  for (final line in envFile.readAsLinesSync()) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.substring('SUPABASE_URL='.length).trim();
    }
  }
  if (supabaseUrl.isEmpty) {
    stderr.writeln('ERROR: SUPABASE_URL is empty in .env');
    exit(1);
  }

  stdout.writeln('Supabase URL: $supabaseUrl');
  stdout.writeln('Checking ${imagePaths.length} image URLs...\n');

  final client = HttpClient();
  var passed = 0;
  var failed = 0;

  for (final entry in imagePaths.entries) {
    final url = Uri.parse(
      '$supabaseUrl/storage/v1/object/public/${entry.value}',
    );
    try {
      final request = await client.headUrl(url);
      final response = await request.close();
      await response.drain<void>();

      final status = response.statusCode;
      final contentType = response.headers.contentType;

      if (status == 200 && contentType?.primaryType == 'image') {
        stdout.writeln('  OK  ${entry.key} ($contentType)');
        passed++;
      } else {
        stderr.writeln('  FAIL  ${entry.key}: HTTP $status ($contentType)');
        if (status == 400 || status == 404) {
          stderr.writeln('        -> Bucket or file not found. '
              'Create "app_assets" bucket (public) and upload ${entry.value.split("/").last}');
        }
        failed++;
      }
    } catch (e) {
      stderr.writeln('  FAIL  ${entry.key}: $e');
      failed++;
    }
  }

  client.close();
  stdout.writeln('\n$passed passed, $failed failed');
  exit(failed > 0 ? 1 : 0);
}
