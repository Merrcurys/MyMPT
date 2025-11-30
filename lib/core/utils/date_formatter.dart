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
  ///
  /// Номер недели начинается с первого дня учебы (1 сентября).
  /// Первый день учебы всегда 1 сентября.
  ///
  /// Параметры:
  /// - [date]: Дата для определения типа недели
  ///
  /// Возвращает:
  /// - String: Тип недели ('Числитель' или 'Знаменатель')
  static String getWeekType(DateTime date) {
    // Определяем начало учебного года
    final startOfYear = DateTime(date.year, 9, 1);

    // Если сейчас до сентября, значит учебный год начался в прошлом году
    final startDate = date.month < 9
        ? DateTime(date.year - 1, 9, 1)
        : startOfYear;

    // Вычисляем количество дней между датой и началом учебного года
    final difference = date.difference(startDate).inDays;

    // Вычисляем номер недели (начинается с 0)
    final weekNumber = (difference ~/ 7);

    // Определяем тип недели: четные недели - числитель, нечетные - знаменатель
    return weekNumber.isEven ? 'Числитель' : 'Знаменатель';
  }
}
