class ScheduleChange {
  final String lessonNumber;
  final String replaceFrom;
  final String replaceTo;
  final String updatedAt; // Timestamp when change was added
  final String changeDate; // Actual date when change applies

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