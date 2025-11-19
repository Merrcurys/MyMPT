/// Сущность, представляющая учебную группу
///
/// Этот класс представляет собой учебную группу с кодом группы
/// и кодом специальности, к которой она относится
class Group {
  /// Код группы
  final String code;

  /// Код специальности, к которой относится группа
  final String specialtyCode;

  /// Конструктор группы
  ///
  /// Параметры:
  /// - [code]: Код группы (обязательный)
  /// - [specialtyCode]: Код специальности (обязательный)
  Group({required this.code, required this.specialtyCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'Group{code: $code, specialtyCode: $specialtyCode}';
  }
}
