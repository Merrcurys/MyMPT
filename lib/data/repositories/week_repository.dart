import 'package:my_mpt/data/models/week_info.dart';
import 'package:my_mpt/core/utils/date_formatter.dart';

class WeekRepository {
  /// Получает информацию о текущей неделе
  ///
  /// Вместо парсинга с сайта, теперь мы вычисляем тип недели самостоятельно
  /// на основе текущей даты и начала учебного года (1 сентября)
  ///
  /// Возвращает:
  /// - WeekInfo: Информация о текущей неделе
  Future<WeekInfo> getWeekInfo() async {
    final now = DateTime.now();
    final weekType = DateFormatter.getWeekType(now);
    final date = '${now.day}.${now.month}.${now.year}';
    final day = DateFormatter.getWeekdayName(now.weekday);

    return WeekInfo(weekType: weekType, date: date, day: day);
  }
}
