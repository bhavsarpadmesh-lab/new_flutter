// Smoke tests for Habit Ledger.
//
// The default Flutter counter test used to live here. It tested an app that no
// longer exists, so it failed on every run. These check the real thing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_flutter/theme/riso.dart';
import 'package:new_flutter/widgets/streak_ribbon.dart';

void main() {
  group('StreakRibbon', () {
    testWidgets('renders one cell per day', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakRibbon(
              days: [true, true, false, true],
              inkColor: Riso.pink,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('reports the tapped day index', (tester) async {
      int? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakRibbon(
              days: const [false, false, false],
              inkColor: Riso.blue,
              onTapDay: (i) => tapped = i,
            ),
          ),
        ),
      );

      // Tap the middle cell of three across the full width.
      final ribbon = tester.getRect(find.byType(StreakRibbon));
      await tester.tapAt(ribbon.center);
      await tester.pump();

      expect(tapped, 1);
    });
  });

  group('StreakRibbon.dateForIndex', () {
    test('last index is today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(StreakRibbon.dateForIndex(27, 28), today);
    });

    test('first index is n-1 days back', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(
        StreakRibbon.dateForIndex(0, 28),
        today.subtract(const Duration(days: 27)),
      );
    });
  });
}
