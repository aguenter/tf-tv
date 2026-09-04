import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/model/participant.dart';
import 'package:tv/session/model/vote.dart';
import '../../helpers/stub_workout_service.dart';
import 'package:tv/session/view/t2_selection_view.dart';
import 'package:tv/session/widget/initials_badge.dart';
import 'package:tv/session/widget/name_bar.dart';

import '../../helpers/test_fixtures.dart';

/// Baut den T2-Screen mit dem echten 9-Kacheln-Katalog (statische
/// Daten aus ux/ux.md §3) und den übergebenen Votes/Teilnehmern.
///
/// Die Testfläche entspricht einem 16:9-TV (1920×1080): Das ist die
/// reale Kiosk-Anzeigefläche, auf der das komplette 3×3-Raster ohne
/// Scrollen sichtbar sein muss (ux/ux.md §2.1 T2).
Future<void> pumpT2(
  WidgetTester tester, {
  List<Vote> votes = const [],
  List<Participant> participants = allParticipants,
  String? trainerWorkoutId,
}) async {
  // Logische Fläche 1920×1080 – entspricht einem 16:9-TV.
  await tester.binding.setSurfaceSize(const Size(1920, 1080));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final workouts = await StubWorkoutService().fetchCatalog();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: T2SelectionView(
        workouts: workouts,
        votes: votes,
        participants: participants,
        trainerWorkoutId: trainerWorkoutId,
      ),
    ),
  );
}

/// Liefert den Karten-Root-Container (der Container mit BoxDecoration,
/// dessen Titel-Text den Workout-Namen trägt).
Container cardForName(WidgetTester tester, String name) {
  final containers = tester.widgetList<Container>(
    find.ancestor(of: find.text(name), matching: find.byType(Container)),
  );
  return containers.firstWhere(
    (container) => container.decoration is BoxDecoration,
  );
}

/// Liefert den Badge-Root-Container (Container mit Text-Kind = Initialen)
/// innerhalb eines Bereichs.
Container badgeIn(WidgetTester tester, Finder scope, String initials) {
  final containers = tester.widgetList<Container>(
    find.descendant(of: scope, matching: find.byType(Container)),
  );
  return containers.firstWhere(
    (container) =>
        container.child is Text && (container.child as Text).data == initials,
  );
}

void main() {
  group('T2 – Workout-Auswahl', () {
    testWidgets('zeigt alle 9 Katalog-Karten mit Schloss-Icon (T2-T1)',
        (tester) async {
      final workouts = await StubWorkoutService().fetchCatalog();
      expect(workouts, hasLength(9));

      await pumpT2(tester);

      for (final workout in workouts) {
        expect(find.text(workout.name), findsOneWidget, reason: workout.name);
      }
      // 3 freigeschaltete + 6 gesperrte Kacheln (ux/ux.md §3).
      expect(find.byIcon(Icons.lock_open), findsNWidgets(3));
      expect(find.byIcon(Icons.lock), findsNWidgets(6));
    });

    testWidgets('zeigt bei 2 Stimmen beide Initialen-Badges + „● 2“ (T2-T2)',
        (tester) async {
      await pumpT2(tester, votes: votesFixture);

      final card = find.byWidget(cardForName(tester, 'Ganzkörper-Blitz'));
      expect(
        find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (widget) => widget is InitialsBadge && widget.initials == 'MM',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (widget) => widget is InitialsBadge && widget.initials == 'LL',
          ),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: card, matching: find.text('● 2')), findsOneWidget);
    });

    testWidgets('hervorhebt die Trainer-Karte mit amberem Rahmen (T2-T3)',
        (tester) async {
      await pumpT2(tester, votes: votesFixture, trainerWorkoutId: 'ganzkoerper-blitz');

      BoxDecoration decorationOf(String name) =>
          cardForName(tester, name).decoration as BoxDecoration;

      // Trainer-Karte: amberer Rahmen.
      final highlighted = decorationOf('Ganzkörper-Blitz');
      expect(highlighted.border, isA<Border>());
      expect((highlighted.border as Border).top.color, Colors.amber);

      // Andere Karte: kein Rahmen.
      final plain = decorationOf('Cardio-Sprint');
      expect((plain.border as Border).top.color, Colors.transparent);
    });

    testWidgets('zeigt in der Namens-Leiste alle Teilnehmer (T2-T4)',
        (tester) async {
      await pumpT2(tester);

      final badges = tester.widgetList<InitialsBadge>(
        find.descendant(of: find.byType(NameBar), matching: find.byType(InitialsBadge)),
      );
      expect(badges.map((badge) => badge.initials).toList(), ['MM', 'LL', 'JJ']);
      // Trainer wird als Trainer markiert (→ amberes Badge).
      expect(
        badges.map((badge) => badge.isTrainer).toList(),
        [true, false, false],
      );

      // Trainer-Badge in Amber, Teilnehmer in Weiß.
      final nameBar = find.byType(NameBar);
      expect(
        (badgeIn(tester, nameBar, 'MM').decoration as BoxDecoration).color,
        Colors.amber.shade700,
      );
      expect(
        (badgeIn(tester, nameBar, 'LL').decoration as BoxDecoration).color,
        isNot(Colors.amber.shade700),
      );
    });

    testWidgets('zeigt auf Karten ohne Stimmen „Noch keine Stimmen“ (T2-T5)',
        (tester) async {
      await pumpT2(tester, votes: votesFixture);

      // 9 Karten, 2 davon mit Stimmen → 7 im Leerzustand.
      expect(find.text('Noch keine Stimmen'), findsNWidgets(7));

      // Karte mit Stimme zeigt keinen Leerzustands-Text.
      expect(
        find.descendant(
          of: find.byWidget(cardForName(tester, 'Ganzkörper-Blitz')),
          matching: find.text('Noch keine Stimmen'),
        ),
        findsNothing,
      );
    });
  });
}
