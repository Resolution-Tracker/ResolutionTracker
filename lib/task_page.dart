import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_item.dart';

/// A page that displays the details of a task and allows for interaction with it.
class DetailsPage extends StatefulWidget {
  /// The task to be displayed on this page.
  final TaskItem task;

  const DetailsPage({super.key, required this.task});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Timer? _timer; // Timer for countdown
  Timer? _resumeTimer; // Timer for resuming after freeze
  bool isFinished = false; // Indicates if the timer has finished
  bool isFrozen = false; // Indicates if the timer is currently frozen
  Duration frozenDuration = const Duration(seconds: 10); // Default freeze duration

  /// Getter to access the task from the widget.
  TaskItem get task => widget.task;

  @override
  void initState() {
    super.initState();
    loadTask();
    setEndTimeAndStartTimer();
  }

  /// Calculates the number of missed intervals since the task's last end time.
  ///
  /// [task] is the task for which missed intervals are calculated.
  /// Returns the number of missed intervals.
  int calculateMissedIntervals(TaskItem task) {
    if (task.endTime == null) {
      return 0;
    }
    Duration elapsed = DateTime.now().difference(task.endTime!);
    if (elapsed.isNegative) {
      return 0;
    }
    return elapsed.inSeconds ~/ task.duration.inSeconds;
  }

  /// Loads the task data from shared preferences and updates the state.
  ///
  /// This includes loading the task's finished and frozen state, and handling any missed intervals.
  void loadTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    bool? finishedState = prefs.getBool('isFinished_${task.title}');
    bool? frozenState = prefs.getBool('isFrozen_${task.title}');

    isFinished = finishedState ?? false;
    isFrozen = frozenState ?? false;

    List<dynamic> tasksList = jsonDecode(tasksJson ?? '[]');
    List<TaskItem> tasks =
        tasksList.map((task) => TaskItem.fromMap(task)).toList();
    int index = tasks.indexWhere((i) => i.title == task.title);
    if (index != -1) {
      setState(() {
        widget.task.streak = tasks[index].streak;
        widget.task.endTime = tasks[index].endTime;
        widget.task.hasCheckedIn = tasks[index].hasCheckedIn;
        widget.task.streakColors = tasks[index].streakColors;
        widget.task.score = tasks[index].score;
      });

      if (!isFrozen) {
        int missedIntervals = calculateMissedIntervals(task);
        for (int i = 0; i < missedIntervals; i++) {
          if (!task.hasCheckedIn) {
            task.updateGridFailed();
            task.streak = 0;
          }
          setEndTimeAndStartTimer();
          task.hasCheckedIn = false;
        }
      }

      if (widget.task.endTime != null && !isFinished && !isFrozen) {
        startTimer();
      } else if (!isFinished && !isFrozen) {
        setEndTimeAndStartTimer();
      }
    } else if (!isFinished && !isFrozen) {
      setEndTimeAndStartTimer();
    }
  }

  /// Sets the end time for the task and starts the timer.
  ///
  /// This method is called whenever the timer needs to be started or restarted.
  void setEndTimeAndStartTimer() {
    setState(() {
      task.endTime = DateTime.now().add(task.duration);
      task.endTime = task.endTime?.add(const Duration(seconds: 2));
      task.countdownTimer = task.endTime!.difference(DateTime.now()); // Immediate update
    });
    startTimer();
  }

  /// Starts the countdown timer for the task.
  ///
  /// This method ensures that the countdown is displayed and handled correctly.
  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer before starting a new one
    if (isFrozen) {
      return;
    }

    setState(() {
      Duration remaining = task.endTime!.difference(DateTime.now());
      task.countdownTimer = remaining;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        Duration remaining = task.endTime!.difference(DateTime.now());
        if (remaining.inSeconds > 0) {
          task.countdownTimer = remaining;
        } else {
          task.countdownTimer = Duration.zero;
          if (!task.hasCheckedIn) {
            setState(() {
              task.updateGridFailed();
              task.streak = 0;
            });
          }
          saveTask();
          setEndTimeAndStartTimer(); // Restart the timer
          task.hasCheckedIn = false;
        }
      });
    });
  }

  /// Saves the current task state to shared preferences.
  ///
  /// This method is called whenever the task state changes.
  void saveTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    List<TaskItem> tasks = [];
    List<dynamic> tasksList = jsonDecode(tasksJson ?? '[]');
    tasks = tasksList.map((task) => TaskItem.fromMap(task)).toList();
    int index = tasks.indexWhere((i) => i.title == task.title);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }

    await prefs.setString(
        'tasks', jsonEncode(tasks.map((task) => task.toMap()).toList()));
    await prefs.setBool('isFinished_${task.title}', isFinished);
    await prefs.setBool('isFrozen_${task.title}', isFrozen);
  }

  /// Handles the check-in action, updating the task state if the user checks in.
  ///
  /// This method ensures that the streak is updated correctly and that the check-in is saved.
  void checkIn() {
    if (!task.hasCheckedIn && !isFinished && !isFrozen) {
      setState(() {
        task.hasCheckedIn = true;
        task.streak += 1;
        if (task.bestStreak < task.streak) {
          task.bestStreak = task.streak;
        }
        task.updateGridCheckIn();
      });
      saveTask();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Already checked in for this interval, timer is finished, or timer is frozen'),
        ),
      );
    }
  }

  /// Finishes the current timer, setting the task as completed.
  ///
  /// This method is called when the user finishes the timer manually.
  void finishTimer() {
    _timer?.cancel();
    setState(() {
      isFinished = true;
      task.countdownTimer = Duration.zero;
    });
    saveTask();
  }

  /// Freezes the timer, pausing it for a set duration.
  ///
  /// This method decreases the task's score and resumes the timer after the frozen duration.
  void freezeTimer() {
    if (task.score >= 10) {
      _timer?.cancel();
      setState(() {
        isFrozen = true;
        task.score -= 10;
      });
      saveTask();

      _resumeTimer = Timer(frozenDuration, () {
        frozenDuration = task.duration;
        setState(() {
          isFrozen = false;
        });
        saveTask();
        setEndTimeAndStartTimer(); // Resume the timer
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough score to freeze the timer')),
      );
    }
  }

  /// Formats a duration into a two-digit string representation.
  ///
  /// [value] is the number to format.
  /// Returns a string representation of the value.
  String _twoDigitFormat(int value) {
    return value.toString().padLeft(2, '0');
  }

  /// Formats a [duration] into a human-readable string.
  ///
  /// If the duration is more than one day, it displays the number of days.
  /// Otherwise, it shows the time in HH:MM:SS format.
  String formatTime(Duration duration) {
    if (duration.inDays > 0) {
      int days = duration.inDays;
      return '$days days';
    } else {
      int hours = duration.inHours;
      int minutes = duration.inMinutes % 60;
      int seconds = duration.inSeconds % 60;
      return '${_twoDigitFormat(hours)}:${_twoDigitFormat(minutes)}:${_twoDigitFormat(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final countdownDisplay = formatTime(task.countdownTimer);

    bool isCheckInEnabled = !isFinished && !isFrozen && !task.hasCheckedIn;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color.fromARGB(255, 237, 234, 227),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: Colors.purple[200],
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CircleAvatar(
              radius: 27,
              backgroundColor: Colors.purple[100],
              child: Text(
                '🏆 ${task.bestStreak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 27,
              backgroundColor: Colors.purple[100],
              child: Text(
                '🔥 ${task.streak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 233, 230, 224),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '⌛ $countdownDisplay ⌛',
                  style: const TextStyle(
                      fontSize: 35, color: Color.fromARGB(255, 206, 147, 216)),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: task.score >= 10 ? freezeTimer : null,
                  icon: const Icon(Icons.ac_unit),
                  iconSize: 40,
                  color: task.score >= 10 ? Colors.purple[200] : Colors.grey,
                  tooltip: 'Freeze',
                ),
                Text('${task.score}/10'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height,
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: task.streakColors.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: task.streakColors[index][200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width: 2.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckInEnabled
                      ? const Color.fromARGB(255, 239, 238, 236)
                      : Colors.grey,
                ),
                onPressed: isCheckInEnabled ? checkIn : null,
                child: const Text(
                  'Check In',
                  style: TextStyle(
                    fontSize: 33.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 206, 147, 216),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 239, 238, 236),
                ),
                onPressed: finishTimer,
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    fontSize: 33.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 206, 147, 216),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
