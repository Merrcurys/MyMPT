import 'package:my_mpt/data/services/week_parser_service.dart';
import 'package:my_mpt/data/models/week_info.dart';

class WeekRepository {
  final WeekParserService _parserService = WeekParserService();
  
  Future<WeekInfo> getWeekInfo() async {
    try {
      final weekInfo = await _parserService.parseWeekInfo();
      return weekInfo;
    } catch (e) {
      return WeekInfo(
        weekType: 'Неизвестно',
        date: 'Неизвестно',
        day: 'Неизвестно',
      );
    }
  }
}