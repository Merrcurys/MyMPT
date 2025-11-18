import 'package:flutter/material.dart';

class BuildingChip extends StatelessWidget {
  final String label;

  const BuildingChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    // Определяем цвета в зависимости от названия здания
    Color borderColor = const Color(0xFFFF8C00).withOpacity(0.3); // Оранжевый по умолчанию
    Color circleColor = const Color(0xFFFF8C00); // Оранжевый по умолчанию
    
    if (label == 'Нежинская') {
      borderColor = const Color(0xFF2196F3).withOpacity(0.3); // Синий для Нежинской
      circleColor = const Color(0xFF2196F3); // Синий для Нежинской
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}