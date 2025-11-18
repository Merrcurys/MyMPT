/// Сущность, представляющая изменение в расписании
class ScheduleChangeEntity {
  final String lessonNumber;
  final String replaceFrom;
  final String replaceTo;
  final String updatedAt; // Timestamp when change was added
  final String changeDate; // Actual date when change applies

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