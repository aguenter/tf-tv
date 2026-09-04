@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that exercise image URLs are reachable from Supabase Storage.
///
/// NOTE: flutter test intercepts all HTTP (returns 400). Run this test with:
///   cd src/tv && dart run test/session/widget/exercise_image_url_test.dart
///
/// Or use the companion shell script:
///   cd src/tv && dart test/session/widget/verify_image_urls.dart
void main() {
  late String supabaseUrl;
  late HttpClient client;

  setUpAll(() {
    final envFile = File('.env');
    if (!envFile.existsSync()) {
      fail('.env file not found – cannot test real URLs');
    }
    supabaseUrl = '';
    for (final line in envFile.readAsLinesSync()) {
      if (line.startsWith('SUPABASE_URL=')) {
        supabaseUrl = line.substring('SUPABASE_URL='.length).trim();
      }
    }
    if (supabaseUrl.isEmpty) {
      fail('SUPABASE_URL is empty in .env');
    }
    client = HttpClient();
  });

  tearDownAll(() {
    client.close();
  });

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

  group('Supabase Storage image URLs are reachable', () {
    for (final entry in imagePaths.entries) {
      test('${entry.key} – ${entry.value} returns HTTP 200', () async {
        final url = Uri.parse(
          '$supabaseUrl/storage/v1/object/public/${entry.value}',
        );
        final request = await client.headUrl(url);
        final response = await request.close();
        await response.drain<void>();

        if (response.statusCode == 400 || response.statusCode == 404) {
          fail(
            '$url returned ${response.statusCode}. '
            'Ensure the "app_assets" bucket exists and is public, '
            'and that ${entry.value.split("/").last} has been uploaded.',
          );
        }

        expect(response.statusCode, 200,
            reason: '$url returned ${response.statusCode}');
      });
    }
  });
}
