/// Сущность, представляющая элемент расписания
class Schedule {
  final String id;
  final String number;
  final String subject;
  final String teacher;
  final String startTime;
  final String endTime;
  final String building;
  final String? lessonType; // numerator, denominator или null для обычных пар

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