import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tv/app/shared/constants.dart';
import 'package:tv/app/shared/theme.dart';
import 'package:tv/session/model/participant.dart';
import 'package:tv/session/view/t1_start_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TeamfitTheme.dark(),
    home: Scaffold(body: child),
  );
}

const _anna = Participant(
  id: 'p-anna',
  displayName: 'Anna',
  initials: 'AN',
  role: ParticipantRole.trainer,
);

const _ben = Participant(
  id: 'p-ben',
  displayName: 'Ben',
  initials: 'BE',
  role: ParticipantRole.participant,
);

const _clara = Participant(
  id: 'p-clara',
  displayName: 'Clara',
  initials: 'CL',
  role: ParticipantRole.participant,
);

void main() {
  group('T1 – Start-Screen', () {
    test('baut den Deep-Link aus Basis + Session-ID (T1-T1)', () {
      expect(
        AppConstants.deepLinkFor('abc123'),
        'https://aguenter.github.io/tf-smartphone/#/join?session=abc123',
      );
    });

    testWidgets('zeigt einen QR-Code (T1-T1)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(sessionId: 'abc123', participants: [])),
      );

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('zeigt das Logo (T1-T2)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(sessionId: 'abc', participants: [])),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('zeigt im Leerzustand „0 Personen dabei" (T1-T3)',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(sessionId: 'abc', participants: [])),
      );

      expect(find.text('0 people joined'), findsOneWidget);
    });

    testWidgets('zählt mehrere Teilnehmer im Plural (T1-T4)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(
          sessionId: 'abc',
          participants: [_anna, _ben, _clara],
        )),
      );

      expect(find.text('3 people joined'), findsOneWidget);
    });

    testWidgets('nutzt Singular für eine Person (T1-T4)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(
          sessionId: 'abc',
          participants: [_anna],
        )),
      );

      expect(find.text('1 person joined'), findsOneWidget);
    });

    testWidgets('zeigt Call-to-Action Text (T1-T5)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(sessionId: 'abc', participants: [])),
      );

      expect(find.text('SCAN THE CODE'), findsOneWidget);
      expect(find.text('and join in!'), findsOneWidget);
    });

    testWidgets('zeigt Avatar-Badges mit Initialen (T1-T6)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(
          sessionId: 'abc',
          participants: [_anna, _ben],
        )),
      );

      expect(find.text('AN'), findsOneWidget);
      expect(find.text('BE'), findsOneWidget);
    });

    testWidgets('keine Badges im Leerzustand (T1-T7)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const T1StartView(sessionId: 'abc', participants: [])),
      );

      expect(find.text('AN'), findsNothing);
    });
  });
}
