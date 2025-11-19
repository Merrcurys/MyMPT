/// Модель урока в расписании
///
/// Этот класс представляет собой отдельный урок в расписании
/// с информацией о времени, предмете, преподавателе и других деталях
class Lesson {
  /// Номер пары
  final String number;

  /// Название предмета
  final String subject;

  /// Преподаватель
  final String teacher;

  /// Время начала пары
  final String startTime;

  /// Время окончания пары
  final String endTime;

  /// Корпус проведения пары
  final String building;

  /// Тип пары (numerator, denominator или null для обычных пар)
  final String? lessonType;

  /// Конструктор урока
  ///
  /// Параметры:
  /// - [number]: Номер пары (обязательный)
  /// - [subject]: Название предмета (обязательный)
  /// - [teacher]: Преподаватель (обязательный)
  /// - [startTime]: Время начала пары (обязательный)
  /// - [endTime]: Время окончания пары (обязательный)
  /// - [building]: Корпус проведения пары (обязательный)
  /// - [lessonType]: Тип пары (опциональный)
  Lesson({
    required this.number,
    required this.subject,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.building,
    this.lessonType,
  });

  @override
  String toString() {
    return 'Lesson(number: $number, subject: $subject, teacher: $teacher, startTime: $startTime, endTime: $endTime, building: $building)';
  }

  /// Преобразует объект урока в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление урока в формате JSON
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'subject': subject,
      'teacher': teacher,
      'startTime': startTime,
      'endTime': endTime,
      'building': building,
    };
  }
}
