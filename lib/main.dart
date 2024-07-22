import 'package:flutter/material.dart';
import 'details_page.dart'; // Import the new page
import 'timer_item.dart'; // Import the TimerItem model
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
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TimerItem> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void addItem(String title, Duration duration) {
    setState(() {
      items.add(TimerItem(title: title, duration: duration));
      saveItems();
    });
  }

  void loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemsJson = prefs.getString('items');
    if (itemsJson != null) {
      List<dynamic> itemsList = jsonDecode(itemsJson);
      setState(() {
        items = itemsList.map((item) => TimerItem.fromMap(item)).toList();
      });
    }
  }

  void saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String itemsJson = jsonEncode(items.map((item) => item.toMap()).toList());
    await prefs.setString('items', itemsJson);
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
      saveItems();
    });
  }

  void _showAddItemDialog() {
    TextEditingController textFieldController = TextEditingController();
    String errorText = '';
    Duration selectedDuration = const Duration(hours: 24); // Default to one day

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textFieldController,
                    decoration: const InputDecoration(hintText: "Enter item"),
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
                                    : '1 Wekk'),
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
                    String newItem = textFieldController.text.trim();
                    if (newItem.isEmpty) {
                      setState(() {
                        errorText = 'Item cannot be blank';
                      });
                    } else {
                      addItem(newItem, selectedDuration);
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

  @override
  Widget build(BuildContext context) {
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
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 2.0), // Add vertical padding here
            child: Dismissible(
              key: Key(items[index].title),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                removeItem(index);
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
                title: Text(items[index].title),
                tileColor: index % 2 == 0
                    ? Colors.blue[50]
                    : Colors.green[50], // Change this to any color you want
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsPage(item: items[index]),
                    ),
                  ).then((_) {
                    saveItems();
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
