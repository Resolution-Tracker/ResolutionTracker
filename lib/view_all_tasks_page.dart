import 'package:flutter/material.dart';
import 'task_item.dart'; // Import the TaskItem model

class ViewAllTasksPage extends StatefulWidget {
  final List<TaskItem> tasks;

  const ViewAllTasksPage({super.key, required this.tasks});

  @override
  _ViewAllTasksPageState createState() => _ViewAllTasksPageState();
}

class _ViewAllTasksPageState extends State<ViewAllTasksPage> {
  Duration selectedDuration = const Duration(seconds: 10); // Default duration set to 10 seconds
  List<TaskItem> filteredTasks = []; // List of tasks being displayed
  final ScrollController controller = ScrollController(); // Scroll controller for synchronizing scroll
  int oldestAge = 0;

  final List<Duration> durations = [ // Possible durations
    const Duration(seconds: 10),
    const Duration(days: 1),
    const Duration(days: 7),
    const Duration(days: 30),
  ];

  @override
  void initState() {
    super.initState();
    filterTasks(selectedDuration); // Filter tasks with default duration
  }

  void filterTasks(Duration duration) {
    setState(() {
      filteredTasks = widget.tasks.where((task) => task.duration == duration).toList();
      selectedDuration = duration;
      oldestAge = findOldestTask(filteredTasks);
    });
  }

  Widget _buildSquare(Color color) {
    return Container(
      width: 40.0,
      height: 40.0,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0), // Curved corners
        border: Border.all(color: Colors.black, width: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        titleTextStyle: TextStyle(
          color: Colors.purple[200],
          fontSize: 30.0,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        actions: [
          DropdownButton<Duration>(
            hint: const Text('Filter by Duration'),
            value: selectedDuration,
            onChanged: (Duration? newValue) {
              if (newValue != null) {
                filterTasks(newValue);
              }
            },
            items: durations.map<DropdownMenuItem<Duration>>((Duration value) {
              return DropdownMenuItem<Duration>(
                value: value,
                child: Text(_formatDuration(value)),
              );
            }).toList(),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: filteredTasks.map((task) {
            return Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 1,
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 206, 147, 216),
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: SingleChildScrollView(
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < oldestAge - task.age; i++)
                            _buildSquare(Colors.grey.shade800), // Using the new method

                          ...task.streakColors.where((color) => color != Colors.grey).map((color) {
                            return _buildSquare(color); // Using the new method
                          }),

                          for (int i = 0; i < 6; i++) // Adding 6 gray squares
                            _buildSquare(Colors.grey), // Using the new method
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == const Duration(seconds: 10)) return '10 seconds';
    if (duration == const Duration(days: 1)) return '1 day';
    if (duration == const Duration(days: 7)) return '1 week';
    if (duration == const Duration(days: 30)) return '1 month';
    return '';
  }

  int findOldestTask(List<TaskItem> tasks) {
    int max = 0;
    for (TaskItem task in tasks) {
      if (task.age > max) {
        max = task.age;
      }
    }
    return max;
  }
}
