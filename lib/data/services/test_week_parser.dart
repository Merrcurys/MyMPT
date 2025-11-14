import 'package:my_mpt/data/services/week_parser_service.dart';
import 'package:my_mpt/data/repositories/week_repository.dart';

/// Тест для проверки работы парсера недели
void main() async {
  print('Тестируем парсер недели...');
  
  // Создаем экземпляр парсера
  final parser = WeekParserService();
  
  try {
    print('Получаем информацию о неделе с сайта...');
    final weekInfo = await parser.parseWeekInfo();
    
    print('Информация о неделе:');
    print('  Тип недели: ${weekInfo.weekType}');
    print('  Дата: ${weekInfo.date}');
    print('  День: ${weekInfo.day}');
    
    // Тестируем репозиторий
    print('\nТестируем репозиторий...');
    final repository = WeekRepository();
    final weekInfoFromRepo = await repository.getWeekInfo();
    
    print('Информация из репозитория:');
    print('  Тип недели: ${weekInfoFromRepo.weekType}');
    print('  Дата: ${weekInfoFromRepo.date}');
    print('  День: ${weekInfoFromRepo.day}');
    
    print('\nТест завершен успешно!');
  } catch (e) {
    print('Ошибка при тестировании: $e');
  }
}