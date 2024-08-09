import 'package:flutter/material.dart';
import 'task_page.dart'; // Import the new page
import 'task_item.dart'; // Import the TaskItem model
import 'view_all_tasks_page.dart'; // Import the new view all tasks page
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TaskItem> tasks = []; //list of tasks to display
  String _sortOption = 'A -> Z'; // default sorting option

  //initial state, just loads tasks
  @override
  void initState() {
    super.initState();
    loadTasks();
  }

//called when the user clicks 'done' when creating a new task
//creates a new task and adds it to the list tasks
  void addTask(String title, Duration duration) {
    setState(() {
      tasks.add(TaskItem(title: title, duration: duration));
      saveTasks();
    });
  }

//called when the home page is opened, loads all the tasks from a stored JSON file
  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> tasksList = jsonDecode(tasksJson);
      setState(() {
        //getting the list of task back from the map
        tasks = tasksList.map((task) => TaskItem.fromMap(task)).toList();
        //sort the tasks by A to Z since thats default option
        _sortTasks();
      });
    }
  }

//saves the task, called at various times, like removing or adding a task, turns the task into a map with toMap (in task_item.dart)
//then converts the map to JSON
  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = jsonEncode(tasks.map((task) => task.toMap()).toList());
    await prefs.setString('tasks', tasksJson);
  }

//removes tasks from tasks
  void removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
      saveTasks();
    });
  }

//this is called when user clicks plus sign
//prompts user for title & duration
  void _showAddTaskDialog() {
    TextEditingController textFieldController = TextEditingController();
    String errorText = '';
    Duration selectedDuration = const Duration(hours: 24); //default duration

    //displays a dialog box
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
                  //this text field prompts user for the title
                  TextField(
                    controller: textFieldController,
                    decoration: const InputDecoration(hintText: "Enter Task"),
                  ),
                  //the dropdown asks for the desired duration
                  DropdownButton<Duration>(
                    value: selectedDuration,
                    onChanged: (Duration? newValue) {
                      setState(() {
                        selectedDuration = newValue!;
                      });
                    },
                    items: <Duration>[
                      const Duration(seconds: 10),
                      const Duration(hours: 1),
                      const Duration(days: 1),
                      const Duration(days: 7)
                    ].map<DropdownMenuItem<Duration>>((Duration value) {
                      return DropdownMenuItem<Duration>(
                        value: value,
                        child: Text(value.inHours == 1
                            ? '1 Hour'
                            : value.inDays == 1
                                ? '1 Day'
                                : value.inSeconds == 10
                                    ? '10 Seconds'
                                    : '1 Week'),
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
              //the following two widgets are just simple cancel and add buttons
              //the cancel, stop creating a new task, add, finalizes the task creation
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
                    if (newTask.isEmpty) { //error text making sure user entered a title
                      setState(() {
                        errorText = 'Task cannot be blank';
                      });
                    } else {
                      //add a new task to tasks, and closes the popup dialog box
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

  //caled when the viewalltasks button is pressed, route the user to view all tasks page
  void _viewAllTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllTasksPage(tasks: tasks),
      ),
    );
  }

//sort tasks by the selected option
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

  //handles the dialog box that shows up to sort the tasks
  //when an option is selected, _sortOption is set to that and _sortTasks() is called
  void _showSortOptions() {
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

  //builds the base home page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //the appbar displays Voyage, the sort button, and viewalltasks page button
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
      //the list of tasks is just a simple column
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
                    //the dismissable allows the user to swipe to delete a task
                    key: Key(tasks[index].title),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      removeTask(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    //listTile determines what each task looks like in the list
                    //alternate between blue & purple
                    //when a task is pushed/pressed Details page is opened and the taks are saved
                    child: ListTile(
                      title: Text(tasks[index].title),
                      tileColor: index % 2 == 0
                          ? Colors.blue[50]
                          : Colors.purple[50],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsPage(task: tasks[index]),
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
          //at the bottom of the screen is the create task button
          //a simple button that on press opens the _showAddTaskDialog
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
