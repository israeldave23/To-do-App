import 'package:flutter/material.dart';
import 'package:to_do_app/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();

  var box = await Hive.openBox("myBox");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSwatch().copyWith(
        //     primary: Colors.lightGreen.shade300,
        //     secondary: Colors.lightGreen.shade400,
        //     tertiary: Colors.black),
        colorScheme: ColorScheme.light().copyWith(
          primary: Colors.lightGreen.shade300,
          secondary: Colors.lightGreen.shade400,
        ),
      ),
    );
  }
}
