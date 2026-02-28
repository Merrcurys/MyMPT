/// Модель информации о преподавателе
class Teacher {
  /// ФИО Преподавателя
  final String teacherName;

  Teacher({required this.teacherName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teacher && runtimeType == other.runtimeType && teacherName == other.teacherName;

  @override
  int get hashCode => teacherName.hashCode;

  @override
  String toString() {
    return 'Teacher{teacherName: $teacherName}';
  }

  Map<String, dynamic> toJson() {
    return {
      'teacherName': teacherName,
    };
  }
}
