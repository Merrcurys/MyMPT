/// Утилита для форматирования дат на русском языке
class DateFormatter {
  static const List<String> _weekdays = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  static const List<String> _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  /// Форматирует объект DateTime в читаемую строку на русском языке
  /// Пример: "Понедельник, 1 января"
  static String formatDayWithMonth(DateTime date) {
    final weekday = _weekdays[(date.weekday - 1) % _weekdays.length];
    final month = _months[(date.month - 1) % _months.length];
    return '$weekday, ${date.day} $month';
  }

  /// Получает русское название дня недели по его номеру в DateTime (1-7)
  static String getWeekdayName(int weekdayNumber) {
    return _weekdays[(weekdayNumber - 1) % _weekdays.length];
  }

  /// Получает русское название месяца по его номеру в DateTime (1-12)
  static String getMonthName(int monthNumber) {
    return _months[(monthNumber - 1) % _months.length];
  }

  /// Определяет тип недели (числитель/знаменатель) на основе даты
  /// Возвращает:
  /// - String: Тип недели ('Числитель' или 'Знаменатель')
  static String getWeekType(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    DateTime startDate;
    if (normalizedDate.month < 9) {
      startDate = DateTime(date.year, 1, 1);
    } else {
      startDate = DateTime(date.year, 9, 1);
    }

    // Находим понедельник первой учебной недели (самый простой способ)
    final firstMonday = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );

    // Находим понедельник текущей недели
    final currentMonday = normalizedDate.subtract(
      Duration(days: normalizedDate.weekday - 1),
    );

    // Считаем количество недель от первого понедельника
    final weekNumber = currentMonday.difference(firstMonday).inDays ~/ 7 + 1;

    return weekNumber % 2 == 1 ? 'Числитель' : 'Знаменатель';
  }
}
