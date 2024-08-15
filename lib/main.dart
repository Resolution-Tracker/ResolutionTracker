import 'package:flutter/material.dart';
import 'task_page.dart'; // Imports the task detail page
import 'task_item.dart'; // Imports the TaskItem model
import 'view_all_tasks_page.dart'; // Imports the view all tasks page
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

/// The main app widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

/// The home page of the app where tasks are displayed.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// A list of tasks displayed on the home page.
  List<TaskItem> tasks = [];

  /// The default sorting option.
  String _sortOption = 'A -> Z';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  /// Adds a new task to the list and saves it.
  ///
  /// [title] is the name of the task.
  /// [duration] is the duration of the task.
  void addTask(String title, Duration duration) {
    setState(() {
      tasks.add(TaskItem(title: title, duration: duration));
      saveTasks();
    });
  }

  /// Loads tasks from shared preferences and sets the state.
  ///
  /// This method is called during the initialization of the state.
  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> tasksList = jsonDecode(tasksJson);
      setState(() {
        tasks = tasksList.map((task) => TaskItem.fromMap(task)).toList();
        _sortTasks(); // Sort tasks after loading them
      });
    }
  }

  /// Saves the current list of tasks to shared preferences.
  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = jsonEncode(tasks.map((task) => task.toMap()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  /// Removes a task from the list by its index and saves the updated list.
  ///
  /// [index] is the position of the task to be removed.
  void removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
      saveTasks();
    });
  }

  /// Displays a dialog for adding a new task.
  ///
  /// The dialog prompts the user for the task title and duration.
  void _showAddTaskDialog() {
    TextEditingController textFieldController = TextEditingController();
    String errorText = '';
    Duration selectedDuration = const Duration(seconds: 10); // Default duration

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text field for task title input
                  TextField(
                    controller: textFieldController,
                    decoration: const InputDecoration(hintText: "Enter Task"),
                  ),
                  // Dropdown for selecting task duration
                  DropdownButton<Duration>(
                    value: selectedDuration,
                    onChanged: (Duration? newValue) {
                      setState(() {
                        selectedDuration = newValue!;
                      });
                    },
                    items: <Duration>[
                      const Duration(seconds: 10),
                      const Duration(days: 1),
                      const Duration(days: 7),
                      Duration(days: 30) // 1 Month
                    ].map<DropdownMenuItem<Duration>>((Duration value) {
                      return DropdownMenuItem<Duration>(
                        value: value,
                        child: Text(
                          value.inDays == 1
                              ? '1 Day'
                              : value.inDays == 7
                                  ? '1 Week'
                                  : value.inDays == 30
                                      ? '1 Month'
                                      : '10 Seconds',
                        ),
                      );
                    }).toList(),
                  ),
                  if (errorText.isNotEmpty)
                    Text(
                      errorText,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () {
                    String newTask = textFieldController.text.trim();
                    if (newTask.isEmpty) {
                      setState(() {
                        errorText = 'Task cannot be blank';
                      });
                    } else {
                      addTask(newTask, selectedDuration);
                      textFieldController.clear();
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Navigates to the view all tasks page.
  ///
  /// Called when the "View All Tasks" button is pressed.
  void _viewAllTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllTasksPage(tasks: tasks),
      ),
    );
  }

  /// Sorts the tasks based on the selected sorting option.
  void _sortTasks() {
    switch (_sortOption) {
      case 'A -> Z':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Z -> A':
        tasks.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Newest First':
        tasks.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case 'Oldest First':
        tasks.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        break;
      case 'Shortest':
        tasks.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'Longest':
        tasks.sort((a, b) => b.duration.compareTo(a.duration));
        break;
    }
  }

  /// Displays the sorting options in a dialog.
  ///
  /// Called when the sort button is pressed.
  void _showSortOptions() {
    //sets _sortOption to the chosen option, then calls _sortTasks()
    //big dialogue box w/ each option
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort Tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('A -> Z'),
                onTap: () {
                  setState(() {
                    _sortOption = 'A -> Z';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Z -> A'),
                onTap: () {
                  setState(() {
                    _sortOption = 'Z -> A';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Newest First'),
                onTap: () {
                  setState(() {
                    _sortOption = 'Newest First';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Oldest First'),
                onTap: () {
                  setState(() {
                    _sortOption = 'Oldest First';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Shortest'),
                onTap: () {
                  setState(() {
                    _sortOption = 'Shortest';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Longest'),
                onTap: () {
                  setState(() {
                    _sortOption = 'Longest';
                    _sortTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appbar which display Voyage and the button to filter and to view all tasks
      appBar: AppBar(
        title: const Text('Voyage'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.purple[200],
          fontSize: 40.0,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            color: Colors.purple[200],
            onPressed: _showSortOptions,
            tooltip: 'Sort Tasks',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            color: Colors.purple[200],
            onPressed: _viewAllTasks,
            tooltip: 'View All Tasks',
          ),
        ],
      ),
      //the body consists mainly of the list of tasks
      //also the create task button at the bottom
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(5),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Dismissible(
                    key: Key(tasks[index].title),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      removeTask(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: ListTile(
                      title: Text(tasks[index].title),
                      //alternate colors to break up the page
                      tileColor: index % 2 == 0
                          ? Colors.blue[50]
                          : Colors.purple[50],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            //when clicked redirects to the task_page
                            builder: (context) =>
                                DetailsPage(task: tasks[index]),
                          ),
                        ).then((_) {
                          saveTasks();
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          //add task button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SizedBox(
              width: 100,
              height: 100,
              child: FloatingActionButton(
                backgroundColor: Colors.purple[100],
                onPressed: _showAddTaskDialog,
                tooltip: 'Add Task',
                child: const Icon(Icons.add, size: 60, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
