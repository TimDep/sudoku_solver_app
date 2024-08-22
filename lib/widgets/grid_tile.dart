import 'package:flutter/material.dart';

class SudokuTile extends StatelessWidget {
  final int value;
  final Color c;

  const SudokuTile({Key? key, required this.value, required this.c}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Container(
        alignment: Alignment.center,
        color: c,
        child: Text(
          value == 0 ? " " : value.toString(),
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
