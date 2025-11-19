/// Модель информации о неделе
///
/// Этот класс представляет собой информацию о текущей неделе,
/// включая тип недели, дату и день недели
class WeekInfo {
  /// Тип недели (числитель или знаменатель)
  final String weekType;

  /// Дата
  final String date;

  /// День недели
  final String day;

  /// Конструктор информации о неделе
  ///
  /// Параметры:
  /// - [weekType]: Тип недели (обязательный)
  /// - [date]: Дата (обязательный)
  /// - [day]: День недели (обязательный)
  WeekInfo({required this.weekType, required this.date, required this.day});

  @override
  String toString() {
    return 'WeekInfo(weekType: $weekType, date: $date, day: $day)';
  }

  /// Преобразует объект информации о неделе в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление информации о неделе в формате JSON
  Map<String, dynamic> toJson() {
    return {'weekType': weekType, 'date': date, 'day': day};
  }
}
