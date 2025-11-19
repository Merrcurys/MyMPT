/// Сущность, представляющая специальность обучения
///
/// Этот класс представляет собой специальность обучения
/// с кодом и названием специальности
class Specialty {
  /// Код специальности
  final String code;

  /// Название специальности
  final String name;

  /// Конструктор специальности
  ///
  /// Параметры:
  /// - [code]: Код специальности (обязательный)
  /// - [name]: Название специальности (обязательный)
  Specialty({required this.code, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Specialty &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'Specialty{code: $code, name: $name}';
  }
}
