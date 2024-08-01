import 'package:flutter/material.dart';
import 'task_item.dart'; // Import the TaskItem model
/*
This page will display all of the user's tasks is a visually pleasing and understandable way
Currently still trying to figure out the best way about this, since some the inconsistency in 
task duration makes it tricky for the user to get a sense of time.
As of now each task can be scrolled serparately
*/
class ViewAllTasksPage extends StatelessWidget {
  final List<TaskItem> tasks;

  const ViewAllTasksPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
  //builds the page
  //current structure:
  //AppBar, displays title & back arrow
  //then main body:
  //  displays each task as title, row of grid
  // only the actual grid is scrollable, easier to scroll with finger on touchscreen than w/ mouse
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: tasks.map((task) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(8.0),
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
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: task.streakColors.map((color) {
                            return Container(
                              width: 30.0, // Increase width
                              height: 30.0, // Increase height
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              color: _getColorFromStreak(color),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

//assigns the int from task.streakColors to a color
  Color _getColorFromStreak(int streakValue) {
    switch (streakValue) {
      case -1:
        return Colors.blue;
      case -2:
        return Colors.grey;
      case -3: 
        return Colors.red;
      // Add more cases if needed
      default:
        return Colors.orange;
    }
  }
}
