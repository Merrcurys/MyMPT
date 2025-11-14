import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки работы парсера
void main() async {
  print('Тестируем парсер MPT...');
  
  // Создаем экземпляр парсера
  final parser = MptParserService();
  
  try {
    print('Получаем список вкладок с сайта...');
    final tabs = await parser.parseTabList();
    
    print('Найдено ${tabs.length} вкладок:');
    for (var tab in tabs) {
      print('  Название: ${tab.name}, Код: ${tab.href}');
    }
    
    // Тестируем репозиторий
    print('\nТестируем репозиторий...');
    final repository = MptRepository();
    final specialties = await repository.getSpecialties();
    
    print('Получено ${specialties.length} специальностей:');
    for (var specialty in specialties) {
      print('  Код: ${specialty.code}, Название: ${specialty.name}');
    }
    
    print('\nТест завершен успешно!');
  } catch (e) {
    print('Ошибка при тестировании: $e');
  }
}