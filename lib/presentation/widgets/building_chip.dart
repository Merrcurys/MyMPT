import 'package:flutter/material.dart';

/// Виджет чипа корпуса
///
/// Этот виджет отображает информацию о корпусе проведения занятий
/// с цветовой индикацией в зависимости от названия корпуса
class BuildingChip extends StatelessWidget {
  /// Название корпуса
  final String label;
  final bool showOverrideIndicator;

  const BuildingChip({
    super.key,
    required this.label,
    this.showOverrideIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем цвета в зависимости от названия здания
    Color borderColor = const Color(
      0xFFFF8C00,
    ).withValues(alpha: 0.3); // Оранжевый по умолчанию
    Color circleColor = const Color(0xFFFF8C00); // Оранжевый по умолчанию
    String displayLabel = label;

    if (label == 'Нежинская') {
      borderColor = const Color(
        0xFF2196F3,
      ).withValues(alpha: 0.3); // Синий для Нежинской
      circleColor = const Color(0xFF2196F3); // Синий для Нежинской
    } else if (label == 'Нахимовский') {
      // Серый цвет для Наxимовского корпуса
      borderColor = const Color(
        0xFF9E9E9E,
      ).withValues(alpha: 0.3); // Серый для Наxимовского
      circleColor = const Color(0xFF9E9E9E); // Серый для Наxимовского
    } else if (label != 'Нахимовский' && label != 'Нежинская') {
      // Если здание не Наxимовский и не Нежинская, показываем "Дистанционно"
      displayLabel = 'Дистанционно';
      borderColor = const Color(
        0xFFFF8C00,
      ).withValues(alpha: 0.3); // Оранжевый для дистанционных занятий
      circleColor = const Color(
        0xFFFF8C00,
      ); // Оранжевый для дистанционных занятий
    }

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
            displayLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (!showOverrideIndicator) {
      return chip;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
        const SizedBox(width: 8),
        chip,
      ],
    );
  }
}
