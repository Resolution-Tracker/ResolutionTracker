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


  void addItem(String title) {
    setState(() {
      items.add(TimerItem(title: title));
      saveItems();
    });
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
                      addItem(newItem);
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
        title: const Text('Flutter Add to Array Example'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(items[index].title),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              removeItem(index);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: ListTile(
              title: Text(items[index].title),
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
