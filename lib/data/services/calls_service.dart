import 'package:my_mpt/data/models/call.dart';

/// Сервис для работы с расписанием звонков
///
/// Этот класс предоставляет информацию о расписании звонков техникума
/// и методы для расчета продолжительности перемен
class CallsService {
  /// Статические данные о расписании звонков
  static final List<Call> _callsData = [
    Call(
      period: '1',
      startTime: '08:30',
      endTime: '10:00',
      description: 'Перемена 10 минут',
    ),
    Call(
      period: '2',
      startTime: '10:10',
      endTime: '11:40',
      description: 'Перемена 20 минут',
    ),
    Call(
      period: '3',
      startTime: '12:00',
      endTime: '13:30',
      description: 'Перемена 20 минут',
    ),
    Call(
      period: '4',
      startTime: '13:50',
      endTime: '15:20',
      description: 'Перемена 10 минут',
    ),
    Call(
      period: '5',
      startTime: '15:30',
      endTime: '17:00',
      description: 'Перемена 5 минут',
    ),
    Call(
      period: '6',
      startTime: '17:05',
      endTime: '18:35',
      description: 'Перемена 5 минут',
    ),
    Call(
      period: '7',
      startTime: '18:40',
      endTime: '20:10',
      description: 'Конец учебного дня',
    ),
  ];

  /// Возвращает список звонков
  ///
  /// Метод возвращает копию статических данных о расписании звонков
  ///
  /// Возвращает:
  /// - List<Call>: Список звонков
  static List<Call> getCalls() {
    return List<Call>.from(_callsData);
  }

  /// Рассчитывает продолжительность перемены между парами
  ///
  /// Метод принимает время окончания предыдущей пары и время начала
  /// следующей пары и возвращает продолжительность перемены в
  /// человекочитаемом формате
  ///
  /// Параметры:
  /// - [lessonEndTime]: Время окончания предыдущей пары (в формате HH:MM)
  /// - [nextLessonStartTime]: Время начала следующей пары (в формате HH:MM)
  ///
  /// Возвращает:
  /// - String: Продолжительность перемены в человекочитаемом формате
  static String getBreakDuration(
    String lessonEndTime,
    String nextLessonStartTime,
  ) {
    try {
      // Разбиваем время на часы и минуты
      final endParts = lessonEndTime.split(':');
      final startParts = nextLessonStartTime.split(':');

      // Парсим часы и минуты
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);

      // Переводим время в минуты
      final endTotalMinutes = endHour * 60 + endMinute;
      final startTotalMinutes = startHour * 60 + startMinute;
      final breakMinutes = startTotalMinutes - endTotalMinutes;

      // Проверяем, что перемена не отрицательная
      if (breakMinutes < 0) return '0 минут';
      // Если перемена меньше часа, возвращаем минуты
      if (breakMinutes < 60) return '$breakMinutes минут';

      // Рассчитываем часы и минуты
      final hours = breakMinutes ~/ 60;
      final minutes = breakMinutes % 60;

      // Форматируем результат с учетом склонения
      if (minutes == 0) {
        return '$hours ${hours == 1 ? 'час' : 'часа'}';
      } else {
        return '$hours ${hours == 1 ? 'час' : 'часа'} $minutes минут';
      }
    } catch (e) {
      // В случае ошибки возвращаем значение по умолчанию
      return '20 минут';
    }
  }
}
