/// Сущность, представляющая элемент расписания
///
/// Этот класс представляет собой элемент расписания с полной информацией
/// о времени, предмете, преподавателе и других деталях
class Schedule {
  /// Уникальный идентификатор элемента расписания
  final String id;

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

  /// Конструктор элемента расписания
  ///
  /// Параметры:
  /// - [id]: Уникальный идентификатор (обязательный)
  /// - [number]: Номер пары (обязательный)
  /// - [subject]: Название предмета (обязательный)
  /// - [teacher]: Преподаватель (обязательный)
  /// - [startTime]: Время начала пары (обязательный)
  /// - [endTime]: Время окончания пары (обязательный)
  /// - [building]: Корпус проведения пары (обязательный)
  /// - [lessonType]: Тип пары (опциональный)
  Schedule({
    required this.id,
    required this.number,
    required this.subject,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.building,
    this.lessonType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Schedule &&
        other.id == id &&
        other.number == number &&
        other.subject == subject &&
        other.teacher == teacher &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.building == building;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      number,
      subject,
      teacher,
      startTime,
      endTime,
      building,
    );
  }
}
