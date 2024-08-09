import 'package:flutter/material.dart';
import 'task_item.dart'; // Import the TaskItem model

class ViewAllTasksPage extends StatefulWidget {
  final List<TaskItem> tasks;

  const ViewAllTasksPage({super.key, required this.tasks});

  @override
  // ignore: library_private_types_in_public_api
  _ViewAllTasksPageState createState() => _ViewAllTasksPageState();
}

class _ViewAllTasksPageState extends State<ViewAllTasksPage> {
  Duration selectedDuration = const Duration(days: 1); // Default duration set to 1 day
  List<TaskItem> filteredTasks = []; //the list of tasks being displayed
  final ScrollController controller = ScrollController(); //in theory should keep the rows scrolling in unison
  int oldestAge = 0;

  final List<Duration> durations = [ //possible durations
    const Duration(seconds: 10),
    const Duration(hours: 1),
    const Duration(days: 1),
    const Duration(days: 7),
    const Duration(days: 30),
  ];

  //initial state, since 1 day will most likely be most common duration, those are the defualt tasks displayed
  @override
  void initState() {
    super.initState();
    filterTasks(selectedDuration); // Filter tasks with default duration
  }

//only adds the tasks to filteredTasks that have the correct duration, called when the sewlected duration is changed 
  void filterTasks(Duration duration) {
    setState(() {
      filteredTasks = widget.tasks.where((task) => task.duration == duration).toList();
      selectedDuration = duration;
      oldestAge = findOldestTask(filteredTasks);
    });
  }

  //the layout of the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //the appbar displays a back arrow to return to the home page, the title and the drop down to filter the displayed tasks
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
      //the body displayed the list of tasks with their title on the left, and the grid on the right
      //the grid is scrollable and *should* all scroll in unison
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
                        color: Colors.black,
                        fontSize: 24.0, // Increase font size
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: SingleChildScrollView(
                      controller: controller, //this should cause the rows to be linked
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          //if the task isnt the oldest, it needs squares before it so all grids are lined up
                          for (int i = 0; i < oldestAge - task.age; i++)
                            Container(
                              width: 40.0,
                              height: 40.0,
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              color: Colors.grey.shade800,
                            ),
                            //no reason to display all of the future day squares, especially if its a newer task and there is alot.
                          ...task.streakColors.where((color) => color != Colors.grey).map((color) {
                            return Container(
                              width: 40.0, // Increase width
                              height: 40.0, // Increase height
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              color: color,
                            );
                          }),
                          //adding a couple future day squares cause it looks nicer
                          for (int i = 0; i < 6; i++) // Adding 6 gray squares
                            Container(
                              width: 40.0,
                              height: 40.0,
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              color: Colors.grey,
                            ),
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

  //what is displayed in the dropdown menu.
  String _formatDuration(Duration duration) {
    if (duration == const Duration(seconds: 10)) return '10 seconds';
    if (duration == const Duration(hours: 1)) return '1 hour';
    if (duration == const Duration(days: 1)) return '1 day';
    if (duration == const Duration(days: 7)) return '1 week';
    if (duration == const Duration(days: 30)) return '1 month';
    return '';
  }
  //using the age member variable finds the old task, only from the filtered tasks
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
