/// Модель изменения в расписании
///
/// Этот класс представляет собой изменение в расписании,
/// например, замену одного предмета на другой
class ScheduleChange {
  /// Номер пары, к которой применяется изменение
  final String lessonNumber;

  /// Исходный предмет (до изменения)
  final String replaceFrom;

  /// Новый предмет (после изменения)
  final String replaceTo;

  /// Время добавления изменения (timestamp)
  final String updatedAt;

  /// Дата применения изменения
  final String changeDate;

  /// Конструктор изменения в расписании
  ///
  /// Параметры:
  /// - [lessonNumber]: Номер пары (обязательный)
  /// - [replaceFrom]: Исходный предмет (обязательный)
  /// - [replaceTo]: Новый предмет (обязательный)
  /// - [updatedAt]: Время добавления изменения (обязательный)
  /// - [changeDate]: Дата применения изменения (обязательный)
  ScheduleChange({
    required this.lessonNumber,
    required this.replaceFrom,
    required this.replaceTo,
    required this.updatedAt,
    required this.changeDate,
  });

  @override
  String toString() {
    return 'ScheduleChange(lessonNumber: $lessonNumber, replaceFrom: $replaceFrom, replaceTo: $replaceTo, updatedAt: $updatedAt, changeDate: $changeDate)';
  }

  /// Преобразует объект изменения в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление изменения в формате JSON
  Map<String, dynamic> toJson() {
    return {
      'lessonNumber': lessonNumber,
      'replaceFrom': replaceFrom,
      'replaceTo': replaceTo,
      'updatedAt': updatedAt,
      'changeDate': changeDate,
    };
  }
}
