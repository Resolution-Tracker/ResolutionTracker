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
  Timer? _timer; // displays the timer
  // ignore: unused_field
  Timer? _resumeTimer; // Add a new Timer for resuming after freeze
  bool isFinished = false;
  bool isFrozen = false;
  // Duration for the freeze
  TaskItem get task => widget.task;
  Duration frozenDuration = const Duration(seconds: 10); 
  
  @override
  void initState() {
    super.initState();
    loadTask();
  }

  //if the task hasnt been opened in a long timer, multipe duration may have passed, so we would need to update grid multiple times.
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

  //loads tasks 
  void loadTask() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? tasksJson = prefs.getString('tasks');
  bool? finishedState = prefs.getBool('isFinished_${task.title}');
  bool? frozenState = prefs.getBool('isFrozen_${task.title}');
  
  if (finishedState != null) {
    isFinished = finishedState;
  }
  if (frozenState != null) {
    isFrozen = frozenState;
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
  } else if (!isFinished && !isFrozen) {
    setEndTimeAndStartTimer();
  }
}



  //self explanatory, starts the displayed timer with the appropriate duration
  void setEndTimeAndStartTimer() {
    setState(() {
      task.endTime = DateTime.now().add(task.duration);
      task.endTime = task.endTime?.add(const Duration(seconds: 2));
    });
    startTimer();
  }


  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer before starting a new one
    if (isFrozen) {
      // If the timer is frozen, don't start a new timer
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        Duration remaining = task.endTime!.difference(DateTime.now());
        if (remaining.inSeconds > 0) {
          task.countdownTimer = remaining;
        } else {
          task.countdownTimer = Duration.zero;
          if (!task.hasCheckedIn) { //if the timer runs out w/o the usrer checking in a red quare is added
            setState(() {
              task.updateGridFailed();
              task.streak = 0;
            });
          }
          //restart the timer and save the task
          saveTask();
          setEndTimeAndStartTimer(); // Restart the timer
          task.hasCheckedIn = false;
        }
      });
    });
  }

  //saves the task to a json file
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
  await prefs.setBool('isFrozen_${task.title}', isFrozen);
}


  //called when the checkin button is pressed
  void checkIn() {
    if (!task.hasCheckedIn && !isFinished && !isFrozen) {
      setState(() {
        task.hasCheckedIn = true;
        task.streak += 1;
        if (task.bestStreak < task.streak) {
          task.bestStreak = task.streak;
        }
        task.updateGridCheckIn(); //update grid
      });
      saveTask();
    } else { //unused now but good for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Already checked in for this interval, timer is finished, or timer is frozen')),
      );
    }
  }

  //finish the task, meaning the timer is frozen and the streak and grid will no longer change nor update
  void finishTimer() {
    _timer?.cancel();
    setState(() {
      isFinished = true;
      task.countdownTimer = Duration.zero;
    });
    saveTask();
  }

  //freeze the timer for one duration, so the streak wont be lost
  //cost 10 score
  //a score is earned everytime the user checks in
  void freezeTimer() {
    if (task.score >= 10) {
      _timer?.cancel();
      setState(() {
        isFrozen = true;
        task.score -= 10;
      });
      saveTask();

      // Set up a timer to resume after the frozen duration
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

  //builds the page
  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(task.countdownTimer.inHours);
    final minutes = twoDigits(task.countdownTimer.inMinutes.remainder(60));
    final seconds = twoDigits(task.countdownTimer.inSeconds.remainder(60));

    // Determine whether the Check In button should be enabled
    bool isCheckInEnabled = !isFinished && !isFrozen && !task.hasCheckedIn;

    return Scaffold(
      // the appbar displays the name of the task, the best streak & the current streak & a back arrow to return to home page
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color.fromARGB(255, 237, 234, 227),
        title: Row(
          children: [
            Expanded( 
              //display the title
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
              //displayed best streak
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
              //displays current streak
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
          //back arrow to return to home page
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 233, 230, 224),
      body: Padding(
        //the body of the page is set up as a column, with the timer & streak freeze button first, then the GridView, then the check-in & finish task button
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40, width: 10),
                Text( // the timer
                  '⌛ $hours:$minutes:$seconds ⌛',
                  style: const TextStyle(fontSize: 35, color: Color.fromARGB(255, 206, 147, 216)),
                ),
                const SizedBox(width: 5),
                IconButton(
                  //the freeze task button
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
                    crossAxisCount: 6, // Number of columns
                    crossAxisSpacing: 10, // Horizontal spacing
                    mainAxisSpacing: 10, // Vertical spacing
                  ),
                  itemCount: task.streakColors.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: task.streakColors[index][200],
                        borderRadius: BorderRadius.circular(10), // Rounded corners
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
                //this button is the check in button
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckInEnabled
                      ? const Color.fromARGB(255, 239, 238, 236) // Enabled color
                      : Colors.grey, // Disabled color
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
                //this is the finosh task button
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 239, 238, 236), // Change this to your desired color
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
