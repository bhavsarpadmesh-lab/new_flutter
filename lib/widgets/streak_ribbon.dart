import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/riso.dart';

/// The signature element.
///
/// Most habit apps draw history as a row of separate dots. This doesn't.
/// Consecutive kept days fuse into one continuous bar with rounded caps, so a
/// long run reads as a single slab and a miss physically severs it. The chain
/// isn't a metaphor you read — it's an object whose integrity you can see.
///
/// It is also the control, not a chart: tapping a day toggles it.
class StreakRibbon extends StatelessWidget {
  /// Oldest day first, today last.
  final List<bool> days;
  final Color inkColor;
  final void Function(int index)? onTapDay;
  final double height;

  const StreakRibbon({
    super.key,
    required this.days,
    required this.inkColor,
    this.onTapDay,
    this.height = 38,
  });

  /// How many days of history to show for a habit.
  ///
  /// A habit created today has no 28-day history, and rendering 28 empty cells
  /// makes a brand new habit look broken. The window starts at a week and
  /// grows with the habit until it caps out.
  static int windowFor(Habit habit, {int max = 28, int min = 7}) {
    final created = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final age = today.difference(created).inDays + 1;
    return age.clamp(min, max);
  }

  /// Builds the kept/missed run for the last [n] days, oldest first.
  static List<bool> spanFor(Habit habit, int n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<bool>.generate(n, (i) {
      final day = today.subtract(Duration(days: n - 1 - i));
      return habit.completedDates.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
      );
    });
  }

  /// The calendar date represented by [index] in a span of [n] days.
  static DateTime dateForIndex(int index, int n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: n - 1 - index));
  }

  @override
  Widget build(BuildContext context) {
    final cap = Radius.circular(height / 2);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Riso.paper2),
        child: Row(
          children: List<Widget>.generate(days.length, (i) {
            final on = days[i];
            final joinsLeft = i > 0 && days[i - 1];
            final joinsRight = i < days.length - 1 && days[i + 1];
            final isToday = i == days.length - 1;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapDay == null ? null : () => onTapDay!(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: on ? inkColor : Colors.transparent,
                    borderRadius: on
                        ? BorderRadius.horizontal(
                            left: joinsLeft ? Radius.zero : cap,
                            right: joinsRight ? Radius.zero : cap,
                          )
                        : null,
                    // Today is marked, but softly when nothing's been kept yet —
                    // a hard black box at the end of an empty track reads as a
                    // rendering glitch rather than "you are here".
                    border: isToday
                        ? Border.all(
                            color: on ? Riso.ink : Riso.paper3,
                            width: on ? 2.5 : 2,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
