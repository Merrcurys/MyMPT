import 'package:flutter/material.dart';
import 'package:my_mpt/domain/entities/schedule.dart';

class NumeratorDenominatorCard extends StatelessWidget {
  final Schedule? numeratorLesson;
  final Schedule? denominatorLesson;
  final String lessonNumber;
  final String startTime;
  final String endTime;

  const NumeratorDenominatorCard({
    super.key,
    required this.numeratorLesson,
    required this.denominatorLesson,
    required this.lessonNumber,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Левая часть - номер пары
          Container(
            width: 60,
            height: 120,
            child: Center(
              child: _NumberBadge(number: lessonNumber),
            ),
          ),
          
          // Центральная часть - пары с разделителем
          Expanded(
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Числитель
                  if (numeratorLesson != null)
                    _buildLessonItem(numeratorLesson!, true),
                  
                  // Разделитель
                  Container(
                    height: 1,
                    color: const Color(0xFF333333),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  
                  // Знаменатель
                  if (denominatorLesson != null)
                    _buildLessonItem(denominatorLesson!, false),
                ],
              ),
            ),
          ),
          
          // Правая часть - время
          Container(
            width: 60,
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Schedule lesson, bool isNumerator) {
    final color = isNumerator 
        ? const Color(0xFFFF8C00) // Оранжевый для числителя
        : const Color(0xFF4FC3F7); // Голубой для знаменателя;
    
    return Expanded(
      child: Row(
        children: [
          // Индикатор типа (числитель/знаменатель)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          
          // Основной контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lesson.subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.teacher,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final String number;

  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}