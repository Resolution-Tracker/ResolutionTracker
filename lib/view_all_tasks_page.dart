import 'package:flutter/material.dart';
import 'task_item.dart'; // Import the TaskItem model

/// A page that displays all tasks, allowing users to filter by duration.
class ViewAllTasksPage extends StatefulWidget {
  final List<TaskItem> tasks;

  const ViewAllTasksPage({super.key, required this.tasks});

  @override
  _ViewAllTasksPageState createState() => _ViewAllTasksPageState();
}

class _ViewAllTasksPageState extends State<ViewAllTasksPage> {
  Duration selectedDuration = const Duration(seconds: 10); // Default duration is 10 seconds.
  List<TaskItem> filteredTasks = []; // List of tasks filtered by the selected duration.
  final ScrollController controller = ScrollController(); // Scroll controller for synchronized scrolling.
  int oldestAge = 0; // Tracks the age of the oldest task for layout purposes.

  final List<Duration> durations = [ // List of possible durations for filtering.
    const Duration(seconds: 10),
    const Duration(days: 1),
    const Duration(days: 7),
    const Duration(days: 30),
  ];

  @override
  void initState() {
    super.initState();
    filterTasks(selectedDuration); // Initially filter tasks using the default duration.
  }

  /// Filters tasks based on the selected [duration].
  ///
  /// This method updates the displayed list of tasks and determines the age of the oldest task.
  void filterTasks(Duration duration) {
    setState(() {
      filteredTasks = widget.tasks.where((task) => task.duration == duration).toList();
      selectedDuration = duration;
      oldestAge = findOldestTask(filteredTasks);
    });
  }

  /// Builds a square widget with the specified [color].
  ///
  /// This square represents a task streak or placeholder in the UI.
  Widget _buildSquare(Color color) {
    return Container(
      width: 40.0,
      height: 40.0,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0), // Adds rounded corners.
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
                          // Add placeholders for days before the task's age.
                          for (int i = 0; i < oldestAge - task.age; i++)
                            _buildSquare(Colors.grey.shade800),

                          // Add streak colors, skipping grey.
                          ...task.streakColors.where((color) => color != Colors.grey).map((color) {
                            return _buildSquare(color);
                          }),

                          // Add 6 gray squares as placeholders.
                          for (int i = 0; i < 6; i++)
                            _buildSquare(Colors.grey),
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

  /// Formats the [duration] to a user-friendly string.
  ///
  /// Returns the duration as a string for display in the dropdown menu.
  String _formatDuration(Duration duration) {
    if (duration == const Duration(seconds: 10)) return '10 seconds';
    if (duration == const Duration(days: 1)) return '1 day';
    if (duration == const Duration(days: 7)) return '1 week';
    if (duration == const Duration(days: 30)) return '1 month';
    return '';
  }

  /// Finds and returns the age of the oldest task in the [tasks] list.
  ///
  /// This method determines the maximum age among the tasks, used for layout.
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
