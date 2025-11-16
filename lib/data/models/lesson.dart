class Lesson {
  final String number;
  final String subject;
  final String teacher;
  final String startTime;
  final String endTime;
  final String building;

  Lesson({
    required this.number,
    required this.subject,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.building,
  });

  @override
  String toString() {
    return 'Lesson(number: $number, subject: $subject, teacher: $teacher, startTime: $startTime, endTime: $endTime, building: $building)';
  }

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
