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
  //widget to build the HomePage
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
  _HomePageState createState() => _HomePageState();
}


//this state is responsible for the HomePage of the App
class _HomePageState extends State<HomePage> {
  List<TaskItem> tasks = []; //this is the list of tasks displayed on the home page


  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void addTask(String title, Duration duration) { //function to create a new task
    setState(() {
      tasks.add(TaskItem(title: title, duration: duration));
      saveTasks();
    });
  }

  void loadTasks() async { //loads all of the tasks from a json file stored locally
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      List<dynamic> tasksList = jsonDecode(tasksJson);
      setState(() {
        tasks = tasksList.map((task) => TaskItem.fromMap(task)).toList();
      });
    }
  }

  void saveTasks() async { //converts the list of tasks to a json file
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksJson = jsonEncode(tasks.map((task) => task.toMap()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  void removeTask(int index) { //removes task from list
    setState(() {
      tasks.removeAt(index);
      saveTasks();
    });
  }

  void _showAddTaskDialog() { //this is called when the user presses the '+' button to add a new task
                              //it prompts the user to enter all of the pertinent info
    TextEditingController textFieldController = TextEditingController();
    String errorText = '';
    Duration selectedDuration = const Duration(hours: 24); // Default to one day

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
                  TextField(
                    controller: textFieldController,
                    decoration: const InputDecoration(hintText: "Enter Task"),
                  ),
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

  void _viewAllTasks() {
    //when the user presses the view all tasks button, this is called which redirects them to the ViewAllTasksPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllTasksPage(tasks: tasks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //builds the HomePage
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyage'),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.purple[200],
        fontSize: 40.0,
        fontWeight: FontWeight.bold,),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(5),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 2.0), // Add vertical padding here
            child: Dismissible(
              key: Key(tasks[index].title),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                removeTask(index);
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: ListTile(
                title: Text(tasks[index].title),
                tileColor: index % 2 == 0
                    ? Colors.blue[50]
                    : Colors.green[50], // Change this to any color you want
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _viewAllTasks,
            tooltip: 'View All Tasks',
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showAddTaskDialog,
            tooltip: 'Add Task',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
