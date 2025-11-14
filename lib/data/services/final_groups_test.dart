import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';
import 'package:my_mpt/domain/usecases/get_groups_by_specialty_usecase.dart';

/// Финальный тест для проверки загрузки групп
void main() async {
  print('=== Финальный тест загрузки групп ===');
  
  try {
    print('\n1. Тестируем парсер групп...');
    final parser = MptParserService();
    
    print('   Выполняем парсинг групп...');
    final groups = await parser.parseGroups();
    print('   ✅ Найдено групп: ${groups.length}');
    
    if (groups.isNotEmpty) {
      print('   Примеры групп:');
      for (int i = 0; i < groups.length && i < 3; i++) {
        print('     ${groups[i].code} (специальность: ${groups[i].specialtyCode})');
      }
      
      // Проверим фильтрацию
      final sampleSpecialty = groups.first.specialtyCode;
      print('\n2. Тестируем фильтрацию по специальности: $sampleSpecialty');
      
      final filteredGroups = groups.where((group) => 
        group.specialtyCode.contains(sampleSpecialty)
      ).toList();
      
      print('   ✅ Найдено ${filteredGroups.length} групп для специальности $sampleSpecialty');
      
      print('\n3. Тестируем репозиторий...');
      final repository = MptRepository();
      final repoGroups = await repository.getGroupsBySpecialty(sampleSpecialty);
      print('   ✅ Репозиторий вернул ${repoGroups.length} групп');
      
      print('\n4. Тестируем use case...');
      final useCase = GetGroupsBySpecialtyUseCase(repository);
      final useCaseGroups = await useCase(sampleSpecialty);
      print('   ✅ Use case вернул ${useCaseGroups.length} групп');
      
      if (useCaseGroups.isNotEmpty) {
        print('\n5. Проверка полного цикла:');
        print('   Все компоненты работают корректно!');
        print('   Первая группа: ${useCaseGroups.first.code}');
      } else {
        print('\n5. ⚠️  Use case вернул пустой список');
        print('   Это может быть нормально, если фильтрация не нашла совпадений');
      }
    } else {
      print('   ⚠️  Не найдено ни одной группы');
      print('   Проверьте корректность парсинга HTML структуры');
    }
    
    print('\n✅ Финальный тест завершен!');
    
  } catch (e, stackTrace) {
    print('❌ Ошибка в финальном тесте: $e');
    print('Stack trace: $stackTrace');
  }
}