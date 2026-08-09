import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/riso.dart';
import '../utils/category_icons.dart';
import '../widgets/streak_ribbon.dart';
import 'add_habit_screen.dart';
import 'habit_details_screen.dart';

const int kSpanDays = 28;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final today = DateTime.now();

    final total = habits.length;
    final kept = habits.where((h) => provider.isHabitCompletedOn(h, today)).length;

    return Scaffold(
      backgroundColor: Riso.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Masthead(date: today, kept: kept, total: total),
            ),
            if (total > 0)
              SliverToBoxAdapter(child: _TodayMeter(kept: kept, total: total)),
            if (total == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyLedger(),
              )
            else
              SliverList.builder(
                itemCount: habits.length,
                itemBuilder: (context, i) => _HabitBand(
                  habit: habits[i],
                  isFirst: i == 0,
                ),
              ),
            // Closes the strata. Without it the last band trails off into empty
            // paper and the whole list reads as unfinished.
            if (total > 0)
              const SliverToBoxAdapter(
                child: SizedBox(height: 3, child: ColoredBox(color: Riso.ink)),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Riso.gutter,
            8,
            Riso.gutter,
            Riso.gutter,
          ),
          child: _BlockButton(
            label: 'Add a habit',
            background: Riso.ink,
            foreground: Riso.paper,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddHabitScreen()),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- masthead

class _Masthead extends StatelessWidget {
  final DateTime date;
  final int kept;
  final int total;

  const _Masthead({required this.date, required this.kept, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 22, Riso.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HABIT LEDGER', style: RisoType.mono(letterSpacing: 2.4)),
              Text(
                DateFormat('EEE d MMM').format(date).toUpperCase(),
                style: RisoType.mono(letterSpacing: 2.4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'TODAY',
            style: RisoType.display(size: 52, height: 0.86, letterSpacing: -1.8),
          ),
          Text(
            total == 0 ? '—' : '$kept/$total',
            style: RisoType.display(
              size: 52,
              height: 0.86,
              letterSpacing: -1.8,
              color: Riso.pink,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ today meter

class _TodayMeter extends StatelessWidget {
  final int kept;
  final int total;

  const _TodayMeter({required this.kept, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((kept / total) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 22, Riso.gutter, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$kept OF $total KEPT',
                style: RisoType.display(size: 15, letterSpacing: -0.2),
              ),
              Text('$pct%', style: RisoType.mono(size: 12, letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 14,
            child: Row(
              children: List<Widget>.generate(total, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      color: i < kept ? Riso.ink : Riso.paper3,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- habit band

class _HabitBand extends StatelessWidget {
  final Habit habit;
  final bool isFirst;

  const _HabitBand({required this.habit, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HabitProvider>();
    final today = DateTime.now();
    final doneToday = provider.isHabitCompletedOn(habit, today);
    final ink = CategoryIcons.getColor(habit.category);
    final window = StreakRibbon.windowFor(habit, max: kSpanDays);
    final span = StreakRibbon.spanFor(habit, window);
    final streak = habit.currentStreak;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Riso.ink, width: isFirst ? 3 : 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 7, Riso.gutter, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _KeepDot(
                on: doneToday,
                label: habit.name,
                onTap: () => provider.toggleHabitCompletion(habit.id!, today),
              ),
              const SizedBox(width: 12),
              // The whole name strip opens the habit, with enough height to be
              // a real tap target. The dot beside it stays a separate control.
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HabitDetailsScreen(habitId: habit.id!),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name.toUpperCase(),
                            style: RisoType.display(
                              size: 19,
                              height: 1.05,
                              color: doneToday
                                  ? Riso.ink.withValues(alpha: 0.42)
                                  : Riso.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryTag(category: habit.category, ink: ink),
                        const SizedBox(width: 8),
                        Text(
                          '›',
                          style: RisoType.display(
                            size: 20,
                            letterSpacing: 0,
                            color: Riso.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: StreakRibbon(
                  days: span,
                  inkColor: ink,
                  onTapDay: (i) => provider.toggleHabitCompletion(
                    habit.id!,
                    StreakRibbon.dateForIndex(i, window),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$streak',
                      style: RisoType.display(
                        size: 34,
                        height: 0.8,
                        letterSpacing: -1.4,
                        // Colour is earned. Zero stays grey.
                        color: streak == 0 ? Riso.paper3 : ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streak == 1 ? 'DAY' : 'DAYS',
                      style: RisoType.mono(size: 9, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeepDot extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;

  const _KeepDot({required this.on, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: 'Mark $label kept today',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Riso.ink, width: 2.5),
          ),
          child: Center(
            child: AnimatedScale(
              scale: on ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Riso.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String category;
  final Color ink;

  const _CategoryTag({required this.category, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ink,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Text(
        category.toUpperCase(),
        style: RisoType.mono(size: 9, letterSpacing: 1.4, color: Colors.white),
      ),
    );
  }
}

// ----------------------------------------------------------- empty ledger

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 40, Riso.gutter, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: Riso.ink),
          const SizedBox(height: 22),
          Text(
            'NOTHING\nTRACKED YET',
            style: RisoType.display(size: 34, height: 0.92, letterSpacing: -1.2),
          ),
          const SizedBox(height: 14),
          Text(
            'Add the first habit and the ledger starts filling in. '
            'Each day you keep it, the bar grows by one.',
            style: RisoType.body(size: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ shared parts

class _BlockButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  const _BlockButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label.toUpperCase(),
          style: RisoType.display(
            size: 15,
            letterSpacing: 0.4,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Reused by the other screens so every full-width action looks identical.
class BlockButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  const BlockButton({
    super.key,
    required this.label,
    this.background = Riso.ink,
    this.foreground = Riso.paper,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _BlockButton(
      label: label,
      background: background,
      foreground: foreground,
      onPressed: onPressed,
    );
  }
}
