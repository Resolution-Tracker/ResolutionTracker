import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyage/view_all_tasks_page.dart'; // Adjust import to your file structure
import 'package:voyage/task_item.dart'; // Adjust import to your file structure

void main() {
  group('TaskItem', () {
    test('toMap and fromMap should serialize and deserialize correctly', () {
      final task = TaskItem(
        title: 'Test Task',
        duration: const Duration(hours: 24),
        streak: 5,
        bestStreak: 10,
        age: 3,
        score: 15,
        hasCheckedIn: true,
      );

      final map = task.toMap();
      final newTask = TaskItem.fromMap(map);

      expect(newTask.title, equals(task.title));
      expect(newTask.duration, equals(task.duration));
      expect(newTask.streak, equals(task.streak));
      expect(newTask.bestStreak, equals(task.bestStreak));
      expect(newTask.age, equals(task.age));
      expect(newTask.score, equals(task.score));
      expect(newTask.hasCheckedIn, equals(task.hasCheckedIn));
    });

    test('updateGridCheckIn should update the streak correctly', () {
      final task = TaskItem(
        title: 'Test Task',
        streakColors: [
          Colors.blue,
          Colors.grey,
          Colors.grey,
          Colors.grey,
          Colors.grey,
          Colors.grey
        ],
      );

      task.updateGridCheckIn();

      expect(task.streakColors[0], equals(Colors.purple));
      expect(task.streakColors[1], equals(Colors.blue));
      expect(task.age, equals(1));
      expect(task.score, equals(1));
      expect(task.hasCheckedIn, equals(true));
    });

    test('updateGridFailed should update the streak correctly', () {
      final task = TaskItem(
        title: 'Test Task',
        streakColors: [
          Colors.blue,
          Colors.grey,
          Colors.grey,
          Colors.grey,
          Colors.grey,
          Colors.grey
        ],
      );

      task.updateGridFailed();

      expect(task.streakColors[0], equals(Colors.red));
      expect(task.streakColors[1], equals(Colors.blue));
      expect(task.age, equals(1));
    });
  });
  testWidgets('ViewAllTasksPage should display tasks filtered by duration', (WidgetTester tester) async {
    // Create some sample tasks with different durations
    final tasks = [
      TaskItem(title: 'Task 1', duration: Duration(seconds: 10)),
      TaskItem(title: 'Task 2', duration: Duration(days: 1)),
      TaskItem(title: 'Task 3', duration: Duration(days: 7)),
      TaskItem(title: 'Task 4', duration: Duration(days: 30)),
      TaskItem(title: 'Task 5', duration: Duration(seconds: 10)),
    ];

    // Build the widget
    await tester.pumpWidget(MaterialApp(
      home: ViewAllTasksPage(tasks: tasks),
    ));

    // Verify the initial state (default to 10 seconds)
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 5'), findsOneWidget);
    expect(find.text('Task 2'), findsNothing);
    expect(find.text('Task 3'), findsNothing);
    expect(find.text('Task 4'), findsNothing);

    // Find the dropdown button
    final dropdownFinder = find.byType(DropdownButton<Duration>);
    
    // Tap the dropdown button to open the menu
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Use find.descendant to tap the correct "10 seconds" option in the dropdown
    final menuFinder = find.descendant(
      of: find.byType(Scrollable), // Assuming options are in a Scrollable widget
      matching: find.text('10 seconds'),
    );

    await tester.tap(menuFinder.first);
    await tester.pumpAndSettle();

    // Verify that tasks with a 10 seconds duration are still displayed
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 5'), findsOneWidget);

    // Now let's test filtering by "1 day"
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final oneDayFinder = find.descendant(
      of: find.byType(Scrollable),
      matching: find.text('1 day'),
    );

    await tester.tap(oneDayFinder.first);
    await tester.pumpAndSettle();

    // Verify that tasks with a 1 day duration are displayed
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Task 3'), findsNothing);
    expect(find.text('Task 4'), findsNothing);
    expect(find.text('Task 5'), findsNothing);

    // Test filtering by "1 week"
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final oneWeekFinder = find.descendant(
      of: find.byType(Scrollable),
      matching: find.text('1 week'),
    );

    await tester.tap(oneWeekFinder.first);
    await tester.pumpAndSettle();

    // Verify that tasks with a 1 week duration are displayed
    expect(find.text('Task 3'), findsOneWidget);
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Task 2'), findsNothing);
    expect(find.text('Task 4'), findsNothing);
    expect(find.text('Task 5'), findsNothing);

    // Test filtering by "1 month"
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final oneMonthFinder = find.descendant(
      of: find.byType(Scrollable),
      matching: find.text('1 month'),
    );

    await tester.tap(oneMonthFinder.first);
    await tester.pumpAndSettle();

    // Verify that tasks with a 1 month duration are displayed
    expect(find.text('Task 4'), findsOneWidget);
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Task 2'), findsNothing);
    expect(find.text('Task 3'), findsNothing);
    expect(find.text('Task 5'), findsNothing);
  });
}
