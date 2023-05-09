import 'package:flutter/material.dart';
import 'package:to_do_app/data/database.dart';
import 'package:to_do_app/util/dialog_box.dart';
import 'package:to_do_app/util/todo_tile.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controller
  final _controller = TextEditingController();
  TodoDataBase db = TodoDataBase();

  //reference a box
  final _myBox = Hive.box('myBox');

  @override
  void initState() {
    // TODO: implement initState
    // checks if it first time opening app
    if (_myBox.get("TODOLIST") == null) {
      db.createInitialData();
    } else {
      //already opened the app
      db.loadData();
    }

    super.initState();
  }

  //Function here

  void onCheckBoxChange(bool? value, int index) {
    setState(() {
      db.todoList[index][1] = !db.todoList[index][1];
    });
    db.updateDataBase();
  }

//Save new Task
  void saveNewTask() {
    setState(() {
      db.todoList.add([_controller.text, false]);
      _controller.text = "";
      Navigator.of(context).pop();
      db.updateDataBase();
    });
  }

  //Delete task
  void deleteTask(int index) {
    setState(() {
      db.todoList.removeAt(index);
      db.updateDataBase();
    });
  }

// Create new task

  void createNewTask() {
    showDialog(
        context: context,
        builder: (context) {
          return DialogBox(
            controller: _controller,
            onSave: saveNewTask,
            onCancel: () => Navigator.of(context).pop(),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen.shade100,
      appBar: AppBar(
        title: Text("TO DO made by: Israel Dave"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: createNewTask,
      ),
      body: ListView.builder(
        itemCount: db.todoList.length,
        itemBuilder: (context, index) {
          return TodoTile(
            taskName: db.todoList[index][0],
            taskCompleted: db.todoList[index][1],
            onChanged: (value) => onCheckBoxChange(value, index),
            deleteFunction: (context) => deleteTask(index),
          );
        },
      ),
    );
  }
}
