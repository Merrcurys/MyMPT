/// Модель информации о группе
///
/// Этот класс представляет собой информацию о группе,
/// включая код группы и информацию о специальности
class GroupInfo {
  /// Код группы
  final String code;

  /// Код специальности
  final String specialtyCode;

  /// Название специальности
  final String specialtyName;

  /// Конструктор информации о группе
  ///
  /// Параметры:
  /// - [code]: Код группы (обязательный)
  /// - [specialtyCode]: Код специальности (обязательный)
  /// - [specialtyName]: Название специальности (обязательный)
  GroupInfo({
    required this.code,
    required this.specialtyCode,
    required this.specialtyName,
  });

  @override
  String toString() {
    return 'GroupInfo(code: $code, specialtyCode: $specialtyCode, specialtyName: $specialtyName)';
  }

  /// Преобразует объект информации о группе в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление информации о группе в формате JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'specialtyCode': specialtyCode,
      'specialtyName': specialtyName,
    };
  }
}
