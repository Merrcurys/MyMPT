/// Модель звонка
///
/// Этот класс представляет собой информацию о звонке,
/// включая время начала, окончания и описание
class Call {
  /// Период (номер пары)
  final String period;

  /// Время начала звонка
  final String startTime;

  /// Время окончания звонка
  final String endTime;

  /// Описание звонка
  final String description;

  /// Конструктор звонка
  ///
  /// Параметры:
  /// - [period]: Период (номер пары) (обязательный)
  /// - [startTime]: Время начала звонка (обязательный)
  /// - [endTime]: Время окончания звонка (обязательный)
  /// - [description]: Описание звонка (обязательный)
  Call({
    required this.period,
    required this.startTime,
    required this.endTime,
    required this.description,
  });

  /// Фабричный конструктор для создания звонка из JSON
  ///
  /// Параметры:
  /// - [json]: Представление звонка в формате JSON
  ///
  /// Возвращает:
  /// - Call: Объект звонка
  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      period: json['period'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      description: json['description'] as String,
    );
  }

  /// Преобразует объект звонка в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление звонка в формате JSON
  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
    };
  }
}
