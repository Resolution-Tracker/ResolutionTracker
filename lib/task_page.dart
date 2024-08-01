import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_item.dart';

/*
This page is responsible for displaying info on an individual task
Page layout is as follows:
AppBar display back arrow, Title, best streak, current streak
Main body display grid, check-in button, finish button
need to make it more clear the difference between the two.

this page also handles the timer which should change in the future.
*/

class DetailsPage extends StatefulWidget {
  final TaskItem task;

  const DetailsPage({super.key, required this.task});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Timer? _timer;
  bool hasCheckedIn = false;
  bool isFinished = false;
  TaskItem get task => widget.task;

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  void loadTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    bool? finishedState = prefs.getBool('isFinished_${task.title}');
    if (finishedState != null) {
      isFinished = finishedState;
    }
    if (tasksJson != null) {
      List<dynamic> tasksList = jsonDecode(tasksJson);
      List<TaskItem> tasks =
          tasksList.map((task) => TaskItem.fromMap(task)).toList();
      int index = tasks.indexWhere((i) => i.title == task.title);
      if (index != -1) {
        setState(() {
          widget.task.streak = tasks[index].streak;
          widget.task.endTime = tasks[index].endTime;
        });
        if (widget.task.endTime != null && !isFinished) {
          startTimer();
        } else if (!isFinished) {
          setEndTimeAndStartTimer();
        }
      } else if (!isFinished) {
        setEndTimeAndStartTimer();
      }
    } else if (!isFinished) {
      setEndTimeAndStartTimer();
    }
  }

  void setEndTimeAndStartTimer() {
    setState(() {
      task.endTime = DateTime.now().add(task.duration);
    });
    startTimer();
  }

  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer before starting a new one
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        Duration remaining = task.endTime!.difference(DateTime.now());
        if (remaining.inSeconds > 0) {
          task.countdownTimer = remaining;
        } else {
          task.countdownTimer = Duration.zero;
          if (!hasCheckedIn) {
            setState(() {
              task.streakColors =
                  updateGridFailed(task.streakColors, task.streak);
              task.streak = 0;
            });
          }
          saveTask();
          setEndTimeAndStartTimer(); // Restart the timer
          hasCheckedIn = false;
        }
      });
    });
  }

  void saveTask() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    List<TaskItem> tasks = [];
    if (tasksJson != null) {
      List<dynamic> tasksList = jsonDecode(tasksJson);
      tasks = tasksList.map((task) => TaskItem.fromMap(task)).toList();
    }
    int index = tasks.indexWhere((i) => i.title == task.title);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    await prefs.setString(
        'tasks', jsonEncode(tasks.map((task) => task.toMap()).toList()));
    await prefs.setBool('isFinished_${task.title}', isFinished);
  }

  void checkIn() {
    if (!hasCheckedIn && !isFinished) {
      setState(() {
        hasCheckedIn = true;
        task.streak += 1;
        if (task.bestStreak < task.streak) {
          task.bestStreak = task.streak;
        }
        task.streakColors = updateGridCheckIn(task.streakColors);
      });
      saveTask();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already checked in for this interval or the timer is finished')),
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  MaterialColor pickColor(int c) {
    if (c == -1) {
      return Colors.blue;
    } else if (c == -2) {
      return Colors.grey;
    } else if (c == -3) {
      return Colors.red;
    } else if (c % 3 == 0) {
      return Colors.green;
    } else if (c % 3 == 1) {
      return Colors.orange;
    } else {
      return Colors.purple;
    }
  }

  List<int> updateGridCheckIn(List<int> streakColors) {
    if (streakColors.indexOf(-1) != 48) {
      streakColors.removeAt(48);
    } else {
      streakColors.removeAt(0);
    }
    streakColors.insert(streakColors.indexOf(-1), 0);

    return streakColors;
  }

  List<int> updateGridFailed(List<int> streakColors, int streak) {
    if (streak > 0) {
      for (int i = 0; i < streakColors.length; i++) {
        if (streakColors[i] >= 0) {
          streakColors[i] += 1;
        }
      }
    }

    if (streakColors.indexOf(-1) != 48) {
      streakColors.removeAt(48);
    } else {
      streakColors.removeAt(0);
    }
    streakColors.insert(streakColors.indexOf(-1), -3);

    return streakColors;
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(task.countdownTimer.inHours);
    final minutes = twoDigits(task.countdownTimer.inMinutes.remainder(60));
    final seconds = twoDigits(task.countdownTimer.inSeconds.remainder(60));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.grey,
        title: Row(
          children: [
            Expanded(child: Text(task.title)),
            Text('${task.bestStreak}🏆'),
            Text('${task.streak} 🔥'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'Time Remaining: $hours:$minutes:$seconds',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // Number of columns
                  crossAxisSpacing: 10, // Horizontal spacing
                  mainAxisSpacing: 10, // Vertical spacing
                ),
                itemCount: task.streakColors.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: pickColor(task.streakColors[index])[200],
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                      border: Border.all(
                        width: 2,
                        color: pickColor(task.streakColors[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              width: 200,
              child: ElevatedButton(
                onPressed: isFinished ? null : checkIn,
                child: const Text(
                  'Check In',
                  style: TextStyle(
                    fontSize: 33.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              width: 200,
              child: ElevatedButton(
                onPressed: finishTimer,
                child: const Text(
                  'Finish',
                  style: TextStyle(
                    fontSize: 33.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }
}
