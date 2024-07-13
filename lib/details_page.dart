import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timer_item.dart';

class DetailsPage extends StatefulWidget {
  final TimerItem item;

  const DetailsPage({super.key, required this.item});

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Timer _timer;
  bool hasCheckedIn = false;
  TimerItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    loadItem();
    startTimer();
  }

  void loadItem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemsJson = prefs.getString('items');
    if (itemsJson != null) {
      List<dynamic> itemsList = jsonDecode(itemsJson);
      List<TimerItem> items =
          itemsList.map((item) => TimerItem.fromMap(item)).toList();
      int index = items.indexWhere((i) => i.title == item.title);
      if (index != -1) {
        setState(() {
          widget.item.streak = items[index].streak;
        });
      }
    }
  }

  void startTimer() {
    setState(() {
      // Convert item.duration (in seconds) to a Duration object
      item.endTime = DateTime.now().add(item.duration);
      debugPrint('Timer started with duration: ${item.duration} seconds');
      hasCheckedIn = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        Duration remaining = item.endTime!.difference(DateTime.now());
        if (remaining.inSeconds > 0) {
          item.countdownTimer = remaining;
        } else {
          if (!hasCheckedIn) {
            setState(() {
              item.streakColors = updateGridFailed(item.streakColors, item.streak);
              debugPrint("${item.streakColors[0]}");
              item.streak = 0;
            });
          }
          saveItem();
          startTimer(); // Restart the timer
          hasCheckedIn = false;
        }
      });
    });
  }

  void saveItem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemsJson = prefs.getString('items');
    List<TimerItem> items = [];
    if (itemsJson != null) {
      List<dynamic> itemsList = jsonDecode(itemsJson);
      items = itemsList.map((item) => TimerItem.fromMap(item)).toList();
    }
    int index = items.indexWhere((i) => i.title == item.title);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await prefs.setString(
        'items', jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  void checkIn() {
    if (!hasCheckedIn) {
      setState(() {
        hasCheckedIn = true;
        item.streak += 1;
        item.streakColors = updateGridCheckIn(item.streakColors);
        debugPrint("${item.streakColors[0]}");
      });
      saveItem();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already checked in for this interval')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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
    final hours = twoDigits(item.countdownTimer.inHours);
    final minutes = twoDigits(item.countdownTimer.inMinutes.remainder(60));
    final seconds = twoDigits(item.countdownTimer.inSeconds.remainder(60));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.grey,
        title: Row(
          children: [
            Expanded(child: Text(item.title)),
            Text('${item.streak} 🔥'),
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
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // Number of columns
                  crossAxisSpacing: 10, // Horizontal spacing
                  mainAxisSpacing: 10, // Vertical spacing
                ),
                itemCount: item.streakColors.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: pickColor(item.streakColors[index])[200],
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                      border: Border.all(
                        width: 2,
                        color: pickColor(item.streakColors[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Countdown Timer: $hours:$minutes:$seconds',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkIn,
              child: const Text('Check In'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
