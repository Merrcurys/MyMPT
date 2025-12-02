import 'package:flutter/material.dart';

/// Виджет секции настроек
class Section extends StatelessWidget {
  final String title;

  const Section({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}
