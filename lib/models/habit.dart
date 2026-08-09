import 'dart:convert';

class Habit {
  final int? id;
  final String name;
  final String description;
  final String category;
  final String? reminderTime;
  final DateTime createdAt;
  final List<DateTime> completedDates;

  Habit({
    this.id,
    required this.name,
    this.description = '',
    this.category = 'Other',
    this.reminderTime,
    required this.createdAt,
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': jsonEncode(
        completedDates.map((date) => date.toIso8601String()).toList(),
      ),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      reminderTime: map['reminderTime'],
      createdAt: DateTime.parse(map['createdAt']),
      completedDates: (jsonDecode(map['completedDates']) as List)
          .map((item) => DateTime.parse(item))
          .toList(),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? reminderTime,
    DateTime? createdAt,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final today = DateTime.now();
    final sortedDates = List<DateTime>.from(completedDates)..sort((a, b) => b.compareTo(a));
    
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final lastCompletion = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);

    // If last completion was before yesterday, streak is broken
    final difference = normalizedToday.difference(lastCompletion).inDays;
    if (difference > 1) return 0;

    int streak = 0;
    DateTime currentCheck = lastCompletion;

    for (var date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (normalizedDate == currentCheck) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else if (normalizedDate.isBefore(currentCheck)) {
        break;
      }
    }

    return streak;
  }

  int get bestStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completedDates)..sort((a, b) => a.compareTo(b));
    
    int maxStreak = 0;
    int currentRun = 0;
    DateTime? lastDate;

    for (var date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      if (lastDate == null) {
        currentRun = 1;
      } else {
        final diff = normalizedDate.difference(lastDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1;
        }
      }
      
      if (currentRun > maxStreak) maxStreak = currentRun;
      lastDate = normalizedDate;
    }

    return maxStreak;
  }
}
