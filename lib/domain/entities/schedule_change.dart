/// Сущность, представляющая изменение в расписании
///
/// Этот класс представляет собой изменение в расписании,
/// например, замену одного предмета на другой
class ScheduleChangeEntity {
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
  ScheduleChangeEntity({
    required this.lessonNumber,
    required this.replaceFrom,
    required this.replaceTo,
    required this.updatedAt,
    required this.changeDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleChangeEntity &&
        other.lessonNumber == lessonNumber &&
        other.replaceFrom == replaceFrom &&
        other.replaceTo == replaceTo &&
        other.updatedAt == updatedAt &&
        other.changeDate == changeDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      lessonNumber,
      replaceFrom,
      replaceTo,
      updatedAt,
      changeDate,
    );
  }
}
