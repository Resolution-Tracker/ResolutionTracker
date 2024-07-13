class TimerItem {
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


  TimerItem({
    required this.title,
    this.duration = const Duration(hours: 24),
    this.countdownTimer = const Duration(hours: 24),
    this.endTime,
    this.lastResetDate,
    this.streak = 0,
    Set<DateTime>? resetDates,
  }) : resetDates = resetDates ?? {};


  factory TimerItem.fromMap(Map<String, dynamic> map) {
    return TimerItem(
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
