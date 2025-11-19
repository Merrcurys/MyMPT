import 'package:my_mpt/data/datasources/schedule_remote_data_source.dart';
import 'package:my_mpt/data/models/lesson.dart';
import 'package:my_mpt/data/parsers/schedule_html_parser.dart';

class ScheduleParserService {
  ScheduleParserService({
    ScheduleRemoteDataSource? remoteDataSource,
    ScheduleHtmlParser? htmlParser,
  })  : _remoteDataSource = remoteDataSource ?? ScheduleRemoteDataSource(),
        _htmlParser = htmlParser ?? ScheduleHtmlParser();

  final ScheduleRemoteDataSource _remoteDataSource;
  final ScheduleHtmlParser _htmlParser;

  /// Парсит расписание для конкретной группы
  Future<Map<String, List<Lesson>>> parseScheduleForGroup(
    String groupCode, {
    bool forceRefresh = false,
  }) async {
    if (groupCode.isEmpty) return {};

    try {
      final html = await _remoteDataSource.fetchSchedulePage(
        forceRefresh: forceRefresh,
      );
      return _htmlParser.parse(html, groupCode);
    } catch (error) {
      throw Exception('Error parsing schedule for group $groupCode: $error');
    }
  }

  void clearCache() => _remoteDataSource.clearCache();
}
