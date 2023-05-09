import 'package:flutter/material.dart';

class MyButtons extends StatelessWidget {
  final String text;
  VoidCallback onPressed;

  MyButtons({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      child: Text(text),
      color: Colors.lightGreen.shade400,
    );
  }
}
