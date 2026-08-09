import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../services/notification_service.dart';
import '../theme/riso.dart';
import '../utils/category_icons.dart';
import '../widgets/streak_ribbon.dart';
import 'add_habit_screen.dart';
import 'home_screen.dart' show BlockButton, kSpanDays;

class HabitDetailsScreen extends StatefulWidget {
  final int habitId;

  const HabitDetailsScreen({super.key, required this.habitId});

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final matches = provider.habits.where((h) => h.id == widget.habitId);

    // The habit was deleted while this screen was still mounted.
    if (matches.isEmpty) return const Scaffold(backgroundColor: Riso.paper);

    final habit = matches.first;
    final ink = CategoryIcons.getColor(habit.category);
    final today = DateTime.now();
    final doneToday = provider.isHabitCompletedOn(habit, today);

    return Scaffold(
      backgroundColor: Riso.paper,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(context, habit),
            _heroStreak(habit, ink),
            _figures(habit),
            _ribbonSection(habit, provider, ink),
            _section(
              'FULL RECORD',
              _calendar(habit, provider, ink),
            ),
            _section('REMINDER', _reminder(habit)),
            _actions(context, habit, provider),
            const SizedBox(height: 24),
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
          child: BlockButton(
            label: doneToday ? 'Undo today' : 'Mark today kept',
            background: doneToday ? Riso.paper3 : ink,
            foreground: doneToday ? Riso.ink : Colors.white,
            onPressed: () =>
                provider.toggleHabitCompletion(habit.id!, DateTime.now()),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- pieces

  Widget _header(BuildContext context, Habit habit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 20, Riso.gutter, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 40),
              child: Text(
                '← TODAY',
                style: RisoType.mono(letterSpacing: 2.2),
              ),
            ),
          ),
          Text(
            habit.name.toUpperCase(),
            style: RisoType.display(size: 40, height: 0.88, letterSpacing: -1.4),
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              habit.description,
              style: RisoType.body(size: 15, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroStreak(Habit habit, Color ink) {
    return Container(
      width: double.infinity,
      color: ink,
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 22, Riso.gutter, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${habit.currentStreak}',
            style: RisoType.display(
              size: 104,
              height: 0.76,
              letterSpacing: -5,
              color: Riso.paper,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            habit.currentStreak == 1 ? 'DAY UNBROKEN' : 'DAYS UNBROKEN',
            style: RisoType.mono(size: 11, letterSpacing: 2.2, color: Riso.paper),
          ),
        ],
      ),
    );
  }

  Widget _figures(Habit habit) {
    final createdDay = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final elapsed = DateTime.now().difference(createdDay).inDays + 1;
    final rate = elapsed <= 0
        ? 0
        : ((habit.completedDates.length / elapsed) * 100).round().clamp(0, 100);

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Riso.ink, width: 1.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fig('${habit.bestStreak}', 'BEST RUN', divider: true),
            _fig('${habit.completedDates.length}', 'TOTAL KEPT', divider: true),
            _fig(
              '$rate%',
              'SINCE ${DateFormat('MMM').format(habit.createdAt).toUpperCase()}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _fig(String value, String label, {bool divider = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: divider
              ? const Border(right: BorderSide(color: Riso.ink, width: 1.5))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: RisoType.display(size: 27, height: 1, letterSpacing: -1),
            ),
            const SizedBox(height: 5),
            Text(label, style: RisoType.mono(size: 9, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _ribbonSection(Habit habit, HabitProvider provider, Color ink) {
    final window = StreakRibbon.windowFor(habit, max: kSpanDays);
    return _section(
      'LAST $window DAYS',
      StreakRibbon(
        days: StreakRibbon.spanFor(habit, window),
        inkColor: ink,
        onTapDay: (i) => provider.toggleHabitCompletion(
          habit.id!,
          StreakRibbon.dateForIndex(i, window),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Riso.ink, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 20, Riso.gutter, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: RisoType.mono(letterSpacing: 2.4)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _calendar(Habit habit, HabitProvider provider, Color ink) {
    final monoDay = RisoType.mono(size: 12, letterSpacing: 0, color: Riso.muted);

    return TableCalendar(
      firstDay: DateTime(
        habit.createdAt.year,
        habit.createdAt.month,
        habit.createdAt.day,
      ),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (day) => provider.isHabitCompletedOn(habit, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() => _focusedDay = focusedDay);
        provider.toggleHabitCompletion(habit.id!, selectedDay);
      },
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      daysOfWeekHeight: 24,
      rowHeight: 42,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        headerPadding: const EdgeInsets.only(bottom: 12),
        titleTextStyle: RisoType.display(size: 20, letterSpacing: -0.6),
        leftChevronIcon: const Icon(Icons.chevron_left, color: Riso.ink),
        rightChevronIcon: const Icon(Icons.chevron_right, color: Riso.ink),
        leftChevronPadding: EdgeInsets.zero,
        rightChevronPadding: EdgeInsets.zero,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: RisoType.mono(size: 9, letterSpacing: 1),
        weekendStyle: RisoType.mono(size: 9, letterSpacing: 1),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.all(2),
        defaultDecoration: const BoxDecoration(color: Riso.paper3),
        weekendDecoration: const BoxDecoration(color: Riso.paper3),
        disabledDecoration: const BoxDecoration(color: Colors.transparent),
        selectedDecoration: BoxDecoration(color: ink),
        todayDecoration: BoxDecoration(
          color: Riso.paper3,
          border: Border.all(color: Riso.ink, width: 2),
        ),
        defaultTextStyle: monoDay,
        weekendTextStyle: monoDay,
        disabledTextStyle: RisoType.mono(
          size: 12,
          letterSpacing: 0,
          color: Riso.paper3,
        ),
        selectedTextStyle: RisoType.mono(
          size: 12,
          letterSpacing: 0,
          color: Colors.white,
        ),
        todayTextStyle: RisoType.mono(
          size: 12,
          letterSpacing: 0,
          color: Riso.ink,
        ),
      ),
    );
  }

  Widget _reminder(Habit habit) {
    final has = habit.reminderTime != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              has ? habit.reminderTime! : 'NONE',
              style: RisoType.display(size: 38, letterSpacing: -1.6),
            ),
            const SizedBox(width: 12),
            Text(
              has ? 'EVERY DAY' : 'NO REMINDER SET',
              style: RisoType.mono(letterSpacing: 1.6),
            ),
          ],
        ),
        if (has) _permissionWarning(),
      ],
    );
  }

  /// A reminder that can never be delivered should say so rather than sit there
  /// looking scheduled.
  Widget _permissionWarning() {
    return FutureBuilder<bool>(
      future: NotificationService().areEnabled(),
      builder: (context, snapshot) {
        if (snapshot.data != false) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await NotificationService().ensurePermission();
              if (mounted) setState(() {});
            },
            child: Container(
              width: double.infinity,
              color: Riso.pink,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              child: Text(
                'NOTIFICATIONS ARE OFF — THIS REMINDER WILL NOT ARRIVE.\nTAP TO ALLOW THEM.',
                style: RisoType.mono(
                  size: 9,
                  letterSpacing: 1.2,
                  color: Riso.paper,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, Habit habit, HabitProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Riso.ink, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(Riso.gutter, 16, Riso.gutter, 16),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddHabitScreen(habit: habit)),
            ),
            child: Text('EDIT HABIT', style: RisoType.mono(letterSpacing: 2.2)),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _confirmDelete(context, habit, provider),
            child: Text(
              'DELETE',
              style: RisoType.mono(letterSpacing: 2.2, color: Riso.pink),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Riso.paper,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Delete ${habit.name}?',
          style: RisoType.display(size: 22, letterSpacing: -0.8),
        ),
        content: Text(
          'The record of ${habit.completedDates.length} kept days goes with it. '
          'This cannot be undone.',
          style: RisoType.body(size: 14, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('KEEP IT', style: RisoType.mono(letterSpacing: 1.8)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'DELETE',
              style: RisoType.mono(letterSpacing: 1.8, color: Riso.pink),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteHabit(habit.id!);
      navigator.pop();
    }
  }
}
