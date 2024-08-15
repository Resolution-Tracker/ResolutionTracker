import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_item.dart';

class DetailsPage extends StatefulWidget {
  final TaskItem task;

  const DetailsPage({super.key, required this.task});

  @override
  // ignore: library_private_types_in_public_api
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Timer? _timer; // Timer for countdown
  Timer? _resumeTimer; // Timer for resuming after freeze
  bool isFinished = false;
  bool isFrozen = false;
  TaskItem get task => widget.task;
  Duration frozenDuration = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    loadTask();
    setEndTimeAndStartTimer();
  }

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

  void setEndTimeAndStartTimer() {
    setState(() {
      task.endTime = DateTime.now().add(task.duration);
      task.endTime = task.endTime?.add(const Duration(seconds: 2));
      task.countdownTimer =
          task.endTime!.difference(DateTime.now()); // Immediate update
    });
    startTimer();
  }

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

  void finishTimer() {
    _timer?.cancel();
    setState(() {
      isFinished = true;
      task.countdownTimer = Duration.zero;
    });
    saveTask();
  }

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

  @override
  Widget build(BuildContext context) {
    String _twoDigitFormat(int value) {
      return value.toString().padLeft(2, '0');
    }

    String formatTime(Duration duration) {
      if (duration.inDays > 0) {
        int days = duration.inDays;
        int hours = duration.inHours % 24;
        int minutes = duration.inMinutes % 60;
        int seconds = duration.inSeconds % 60;
        return '$days days';
      } else {
        int hours = duration.inHours;
        int minutes = duration.inMinutes % 60;
        int seconds = duration.inSeconds % 60;
        return '${_twoDigitFormat(hours)}:${_twoDigitFormat(minutes)}:${_twoDigitFormat(seconds)}';
      }
    }

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
