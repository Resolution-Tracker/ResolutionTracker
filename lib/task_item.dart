/*
The core object of our app
duration is what the user selects for the timer ex 1 day or 1 week
streak colors is still kinda a WIP, should update in size as the task gets older or has existed for longer
currently just always 49 units long
*/

class TaskItem {
  String title;
  Duration duration;
  DateTime? endTime;
  DateTime? lastResetDate;
  int streak;
  Set<DateTime> resetDates;
  Duration countdownTimer;
  List<int> streakColors = [
  -1, -2, -2, -2, -2, -2, -2, -2, -2, -2,
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
  -2, -2, -2, -2, -2, -2, -2, -2, -2, ];
  int bestStreak;




  TaskItem({
    required this.title,
    this.duration = const Duration(hours: 24),
    this.countdownTimer = const Duration(hours: 24),
    this.endTime,
    this.lastResetDate,
    this.streak = 0,
    this.bestStreak = 0,
    Set<DateTime>? resetDates,
  }) : resetDates = resetDates ?? {};



//the following two function convert the tasks to and from a map to make saving to json easier
  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      title: map['title'],
      duration: Duration(seconds: map['duration']),
      countdownTimer: Duration(seconds: map['duration']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      lastResetDate: map['lastResetDate'] != null ? DateTime.parse(map['lastResetDate']) : null,
      streak: map['streak'],
      resetDates: (map['resetDates'] as List).map((date) => DateTime.parse(date)).toSet(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'duration': duration.inSeconds,
      'endTime': endTime?.toIso8601String(),
      'lastResetDate': lastResetDate?.toIso8601String(),
      'streak': streak,
      'resetDates': resetDates.map((date) => date.toIso8601String()).toList(),
    };
  }
}
