/// Модель специальности
///
/// Этот класс представляет собой информацию о специальности,
/// включая код и название специальности
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

  /// Фабричный конструктор для создания специальности из JSON
  ///
  /// Параметры:
  /// - [json]: Представление специальности в формате JSON
  ///
  /// Возвращает:
  /// - Specialty: Объект специальности
  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  /// Преобразует объект специальности в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление специальности в формате JSON
  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name};
  }

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
