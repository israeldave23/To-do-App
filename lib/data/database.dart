import 'package:hive_flutter/hive_flutter.dart';

class TodoDataBase {
  //List of To do's
  List todoList = [];

  final _myBox = Hive.box("myBox");

  //first time opening app data
  void createInitialData() {
    todoList = [
      ["Cook breakfast", false],
      ["Go to office", false],
    ];
  }

  //Loading data from database
  void loadData() {
    todoList = _myBox.get("TODOLIST");
  }

//  Update Database
  void updateDataBase() {
    _myBox.put("TODOLIST", todoList);
  }
}
