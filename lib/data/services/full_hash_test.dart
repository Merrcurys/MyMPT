import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';
import 'package:my_mpt/domain/usecases/get_groups_by_specialty_usecase.dart';

/// Полный тест работы с хешами специальностей
void main() async {
  print('=== Полный тест работы с хешами специальностей ===');
  
  try {
    final parser = MptParserService();
    final repository = MptRepository();
    final useCase = GetGroupsBySpecialtyUseCase(repository);
    
    // Получаем список всех табов
    print('\n1. Получаем список табов...');
    final tabs = await parser.parseTabList();
    print('   Найдено табов: ${tabs.length}');
    
    if (tabs.isNotEmpty) {
      print('\n2. Список табов:');
      for (int i = 0; i < tabs.length && i < 5; i++) {
        print('   $i. href: "${tabs[i].href}" -> name: "${tabs[i].name}"');
      }
      
      // Пробуем получить группы для первого таба через use case
      print('\n3. Получаем группы для первого таба через use case...');
      final firstTabHref = tabs[0].href;
      print('   Хеш первого таба: $firstTabHref');
      
      final groups = await useCase(firstTabHref);
      print('   Найдено групп: ${groups.length}');
      
      if (groups.isNotEmpty) {
        print('   Первые 3 группы:');
        for (int i = 0; i < groups.length && i < 3; i++) {
          print('     ${groups[i].code}');
        }
      }
      
      // Пробуем получить группы для конкретного хеша из логов
      print('\n4. Получаем группы для хеша из логов...');
      final testHash = '#5a2462f4f2cdc10da3e787189fa33a1c';
      print('   Тестовый хеш: $testHash');
      
      final testGroups = await useCase(testHash);
      print('   Найдено групп: ${testGroups.length}');
      
      if (testGroups.isNotEmpty) {
        print('   Первые 3 группы:');
        for (int i = 0; i < testGroups.length && i < 3; i++) {
          print('     ${testGroups[i].code}');
        }
      }
    }
    
    print('\n=== Полный тест завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
  }
}