/// Модель группы
///
/// Этот класс представляет собой информацию о группе,
/// включая код группы и код специальности
class Group {
  /// Код группы
  final String code;

  /// Код специальности
  final String specialtyCode;

  /// Конструктор группы
  ///
  /// Параметры:
  /// - [code]: Код группы (обязательный)
  /// - [specialtyCode]: Код специальности (обязательный)
  Group({required this.code, required this.specialtyCode});

  /// Фабричный конструктор для создания группы из JSON
  ///
  /// Параметры:
  /// - [json]: Представление группы в формате JSON
  ///
  /// Возвращает:
  /// - Group: Объект группы
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      code: json['code'] as String,
      specialtyCode: json['specialtyCode'] as String,
    );
  }

  /// Преобразует объект группы в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление группы в формате JSON
  Map<String, dynamic> toJson() {
    return {'code': code, 'specialtyCode': specialtyCode};
  }

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
