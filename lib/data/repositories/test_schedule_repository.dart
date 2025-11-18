import 'package:my_mpt/data/repositories/schedule_parser_repository.dart';

/// Тест для проверки работы репозитория расписания
Future<void> main() async {
  print('Тестируем репозиторий расписания...');

  try {
    final parserRepo = ScheduleParserRepository();

    print('Получаем расписание на сегодня...');
    final todaySchedule = await parserRepo.getTodaySchedule();
    print('Найдено ${todaySchedule.length} уроков на сегодня:');
    for (var lesson in todaySchedule) {
      print(
        '  ${lesson.number}. ${lesson.subject} - ${lesson.teacher} (${lesson.building})',
      );
    }

    print('\nПолучаем расписание на завтра...');
    final tomorrowSchedule = await parserRepo.getTomorrowSchedule();
    print('Найдено ${tomorrowSchedule.length} уроков на завтра:');
    for (var lesson in tomorrowSchedule) {
      print(
        '  ${lesson.number}. ${lesson.subject} - ${lesson.teacher} (${lesson.building})',
      );
    }

    print('\nТест завершен успешно!');
  } catch (e) {
    print('Ошибка при тестировании репозитория: $e');
  }
}
