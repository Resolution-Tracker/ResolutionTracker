import 'package:flutter/material.dart';

// A list of grey colors to be used when adding a new line of colors
List<MaterialColor> addLine = [
  Colors.grey,
  Colors.grey,
  Colors.grey,
  Colors.grey,
  Colors.grey,
  Colors.grey
];

class TaskItem {
  String title; // Title of the task
  int score; // Score for the task
  Duration duration; // Duration set for the task timer
  DateTime? endTime; // End time of the task
  DateTime? lastResetDate; // Last date the task was reset
  int streak; // Current streak count
  Set<DateTime> resetDates; // Set of dates when the task was reset
  Duration countdownTimer; // Timer counting down for the task
  DateTime creationDate; // Date when the task was created
  bool hasCheckedIn; // Whether the user has checked in for the task
  List<MaterialColor> streakColors; // Colors representing the streak
  int bestStreak; // The best streak count achieved
  int age; // Age of the task in days

  // Constructor for the TaskItem class
  TaskItem({
    required this.title,
    this.duration = const Duration(hours: 24),
    this.countdownTimer = const Duration(hours: 24),
    this.endTime,
    this.lastResetDate,
    this.streak = 0,
    this.bestStreak = 0,
    this.age = 0,
    this.score = 0,
    this.hasCheckedIn = false,
    Set<DateTime>? resetDates,
    DateTime? creationDate,
    List<MaterialColor>? streakColors, // Pass streakColors here
  })  : resetDates = resetDates ?? {},
        creationDate = creationDate ?? DateTime.now(),
        streakColors = streakColors ?? [
              Colors.blue,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey,
              Colors.grey
            ];

  // Convert the TaskItem to a map for JSON serialization
  Map<String, dynamic> toMap() {
    List<int> colorValues = streakColors.map((color) => color.value).toList();
    return {
      'title': title,
      'durationSeconds': duration.inSeconds,
      'countdownTimerSeconds': countdownTimer.inSeconds,
      'endTime': endTime?.toIso8601String(),
      'lastResetDate': lastResetDate?.toIso8601String(),
      'streak': streak,
      'bestStreak': bestStreak,
      'age': age,
      'score': score,
      'hasCheckedIn': hasCheckedIn,
      'resetDates': resetDates.map((date) => date.toIso8601String()).toList(),
      'creationDate': creationDate.toIso8601String(),
      'colors': colorValues,
    };
  }

  // Convert a map to a TaskItem
  factory TaskItem.fromMap(Map<String, dynamic> map) {
    List<int> colorValues = (map['colors'] as List<dynamic>?)
        ?.map((value) => value as int)
        .toList() ?? [];

    // Convert to MaterialColor
    List<MaterialColor> materialColors = colorValues
        .map((value) => _materialColorFromValue(value))
        .toList();

    return TaskItem(
      title: map['title'],
      duration: Duration(seconds: map['durationSeconds']),
      countdownTimer: Duration(seconds: map['countdownTimerSeconds']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      lastResetDate: map['lastResetDate'] != null ? DateTime.parse(map['lastResetDate']) : null,
      streak: map['streak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      age: map['age'] ?? 0,
      score: map['score'] ?? 0,
      hasCheckedIn: map['hasCheckedIn'] ?? false,
      resetDates: map['resetDates'] != null
          ? (map['resetDates'] as List<dynamic>)
              .map((e) => DateTime.parse(e))
              .toSet()
          : {},
      creationDate: map['creationDate'] != null ? DateTime.parse(map['creationDate']) : null,
      streakColors: materialColors
    );
  }

  // Update the streakColors list and other properties when the user checks in
  void updateGridCheckIn() {
    int index = streakColors.indexOf(Colors.blue);
    if (index != -1) {
      streakColors[index] = Colors.purple;
      streakColors[index + 1] = Colors.blue;

      // Add more grey colors if nearing the end of the current streakColors list
      if (streakColors.length - streakColors.indexOf(Colors.blue) == 6) {
        streakColors.addAll(addLine);
      }

      age++;
      score++;
      hasCheckedIn = true;
    }
  }

  // Update the streakColors list and other properties when the user fails to check in
  void updateGridFailed() {
    int index = streakColors.indexOf(Colors.blue);
    if (index != -1) {
      streakColors[index] = Colors.red;
      streakColors[index + 1] = Colors.blue;

      // Add more grey colors if nearing the end of the current streakColors list
      if (streakColors.length - streakColors.indexOf(Colors.blue) == 6) {
        streakColors.addAll(addLine);
      }

      age++;
    }
  }
}

MaterialColor _materialColorFromValue(int value) {
  return <MaterialColor>[
    Colors.blue,
    Colors.red,
    Colors.grey,
    Colors.purple,
    // Add other MaterialColors as needed
  ].firstWhere((color) => color.value == value, orElse: () => Colors.grey);
}
