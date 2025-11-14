import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки маппинга хешей в репозитории
void main() async {
  print('=== Тест маппинга хешей в репозитории ===');
  
  try {
    final parserService = MptParserService();
    final tabs = await parserService.parseTabList();
    print('Найдено табов: ${tabs.length}');
    
    if (tabs.isNotEmpty) {
      print('\nСписок табов:');
      for (int i = 0; i < tabs.length; i++) {
        print('$i. href: "${tabs[i].href}" -> name: "${tabs[i].name}"');
      }
      
      // Проверим маппинг хешей
      print('\nПроверка маппинга хешей:');
      final Map<String, String> hashToSpecialtyCode = {};
      for (var tab in tabs) {
        // Извлекаем код специальности из href
        String specialtyCodeFromHref = tab.href;
        if (specialtyCodeFromHref.startsWith('#specialty-')) {
          // Преобразуем '#specialty-09-02-01-e' в '09.02.01 Э'
          specialtyCodeFromHref = specialtyCodeFromHref.substring(11)
              .toUpperCase()
              .replaceAll('-', '.')
              .replaceAll('E', 'Э')
              .replaceAll('P', 'П')
              .replaceAll('T', 'Т')
              .replaceAll('IS', 'ИС')
              .replaceAll('BD', 'БД')
              .replaceAll('VD', 'ВД');
        } else if (specialtyCodeFromHref.startsWith('#')) {
          // Для хешей типа #942c7895202110541adecebcd7f18dd7
          // используем имя таба как код специальности
          specialtyCodeFromHref = tab.name;
        }
        
        // Маппинг: хеш -> код специальности
        hashToSpecialtyCode[tab.href] = specialtyCodeFromHref;
        print('Маппинг: ${tab.href} -> $specialtyCodeFromHref');
      }
      
      // Проверим конкретный хеш из логов
      final testHash = '#942c7895202110541adecebcd7f18dd7';
      if (hashToSpecialtyCode.containsKey(testHash)) {
        print('\nНайден хеш $testHash -> ${hashToSpecialtyCode[testHash]}');
      } else {
        print('\nХеш $testHash не найден в маппинге');
      }
    }
    
    print('\n=== Тест завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
  }
}