# Voyage

## Description
Voyage is a mobile app that allows users to track their goals via the completion of certain timed resolutions, providing comsetic rewards for each goal completed.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learning Dart Basics](https://dart.dev/language)
- [Dart Tutorials](https://dart.dev/tutorials)
- [GeeksforGeeks Article on Dart](https://www.geeksforgeeks.org/dart-tutorial/)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [GeeksforGeeks Article on Flutter](https://www.geeksforgeeks.org/flutter-tutorial/)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Diving into the Codebase

- All _*important*_ code is located in the /lib folder
- Files main.dart, task_item.dart, and view_all_tasks_page.dart are differnt views or pages within the app
- The task_item.dart defines a object that is used to store all information about about a differnt tasks
  - multiple of these objects create the basis of the app
- main.dart is the home page of the app, where you are launched into when you begin
- view_all_tasks.dart can be navigated to from the main.dart when you press the view all tasks button
- task_page.dart can also be navigated to from main.dart, this is activated when a task item is clicked on the home page
- task_page shows a detailed view of an idividual task, remember the task_item.dart file defines the object we use to store and show all of this information
- view_all_tasks.dart shows a overview of all your tasks and their current streak, again the same object is used
