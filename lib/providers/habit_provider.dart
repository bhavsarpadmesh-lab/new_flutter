import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class HabitProvider with ChangeNotifier {
  List<Habit> _habits = [];

  List<Habit> get habits => [..._habits];

  Future<void> fetchHabits() async {
    _habits = await DatabaseHelper.instance.readAllHabits();
    notifyListeners();
  }

  Future<void> addHabit(String name, String description, String category, String? reminderTime) async {
    final newHabit = Habit(
      name: name,
      description: description,
      category: category,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
      completedDates: [],
    );
    final id = await DatabaseHelper.instance.createHabit(newHabit);

    if (reminderTime != null) {
      await _scheduleNotification(id, name, reminderTime);
    }

    await fetchHabits();
  }

  Future<void> editHabit(Habit updatedHabit) async {
    await DatabaseHelper.instance.updateHabit(updatedHabit);
    
    if (updatedHabit.reminderTime != null) {
      await _scheduleNotification(
        updatedHabit.id!,
        updatedHabit.name,
        updatedHabit.reminderTime!,
      );
    } else {
      await NotificationService().cancelNotification(updatedHabit.id!);
    }

    await fetchHabits();
  }

  Future<void> _scheduleNotification(
    int id,
    String name,
    String timeStr,
  ) async {
    // Nothing can be posted without permission, so don't bother scheduling.
    if (!await NotificationService().ensurePermission()) return;

    final parts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    await NotificationService().scheduleDailyNotification(
      id: id,
      title: name,
      body: 'Time to keep this one.',
      time: time,
    );
  }

  Future<void> deleteHabit(int id) async {
    await DatabaseHelper.instance.deleteHabit(id);
    await NotificationService().cancelNotification(id);
    await fetchHabits();
  }

  Future<void> toggleHabitCompletion(int id, DateTime date) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      List<DateTime> updatedDates = List.from(habit.completedDates);
      if (updatedDates.any((d) => _isSameDay(d, dateOnly))) {
        updatedDates.removeWhere((d) => _isSameDay(d, dateOnly));
      } else {
        updatedDates.add(dateOnly);
      }

      final updatedHabit = habit.copyWith(completedDates: updatedDates);
      await DatabaseHelper.instance.updateHabit(updatedHabit);
      await fetchHabits();
    }
  }

  bool isHabitCompletedOn(Habit habit, DateTime date) {
    return habit.completedDates.any((d) => _isSameDay(d, date));
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
