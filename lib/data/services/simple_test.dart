import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';

void main() async {
  print('Запуск теста парсера...');
  
  // Тестируем парсер
  final parser = MptParserService();
  try {
    print('Получаем список вкладок...');
    final tabs = await parser.parseTabList();
    print('Найдено ${tabs.length} вкладок');
    
    for (var tab in tabs) {
      print('  ${tab.name}');
    }
  } catch (e) {
    print('Ошибка при парсинге: $e');
  }
  
  // Тестируем репозиторий
  print('\nТестируем репозиторий...');
  final repository = MptRepository();
  try {
    final specialties = await repository.getSpecialties();
    print('Получено ${specialties.length} специальностей');
    
    for (var specialty in specialties) {
      print('  ${specialty.name}');
    }
  } catch (e) {
    print('Ошибка при получении специальностей: $e');
  }
  
  print('\nТест завершен.');
}