import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';
import 'package:my_mpt/domain/usecases/get_groups_by_specialty_usecase.dart';

/// Расширенный отладочный тест для проверки загрузки групп
void main() async {
  print('=== Расширенная диагностика загрузки групп ===');
  
  try {
    print('\n1. Тестируем парсер напрямую...');
    final parser = MptParserService();
    
    print('   Запрашиваем группы...');
    final startTime = DateTime.now();
    final groups = await parser.parseGroups();
    final endTime = DateTime.now();
    
    print('   Запрос выполнен за ${endTime.difference(startTime).inMilliseconds} мс');
    print('   Найдено групп: ${groups.length}');
    
    if (groups.isNotEmpty) {
      print('   Первые 5 групп:');
      for (int i = 0; i < groups.length && i < 5; i++) {
        print('     ${groups[i].code} - ${groups[i].specialtyCode}');
      }
    } else {
      print('   ❌ Не найдено ни одной группы');
    }
    
    print('\n2. Тестируем репозиторий...');
    final repository = MptRepository();
    
    if (groups.isNotEmpty) {
      final sampleSpecialty = groups.first.specialtyCode;
      print('   Тестируем загрузку групп для специальности: $sampleSpecialty');
      
      final repoStartTime = DateTime.now();
      final repoGroups = await repository.getGroupsBySpecialty(sampleSpecialty);
      final repoEndTime = DateTime.now();
      
      print('   Запрос к репозиторию выполнен за ${repoEndTime.difference(repoStartTime).inMilliseconds} мс');
      print('   Найдено групп в репозитории: ${repoGroups.length}');
      
      if (repoGroups.isNotEmpty) {
        print('   Первые 5 групп из репозитория:');
        for (int i = 0; i < repoGroups.length && i < 5; i++) {
          print('     ${repoGroups[i].code}');
        }
      } else {
        print('   ⚠️  Репозиторий вернул пустой список групп');
      }
    }
    
    print('\n3. Тестируем use case...');
    if (groups.isNotEmpty) {
      final sampleSpecialty = groups.first.specialtyCode;
      print('   Тестируем use case для специальности: $sampleSpecialty');
      
      final useCase = GetGroupsBySpecialtyUseCase(repository);
      final useCaseStartTime = DateTime.now();
      final useCaseGroups = await useCase(sampleSpecialty);
      final useCaseEndTime = DateTime.now();
      
      print('   Запрос к use case выполнен за ${useCaseEndTime.difference(useCaseStartTime).inMilliseconds} мс');
      print('   Найдено групп через use case: ${useCaseGroups.length}');
      
      if (useCaseGroups.isNotEmpty) {
        print('   Первые 5 групп через use case:');
        for (int i = 0; i < useCaseGroups.length && i < 5; i++) {
          print('     ${useCaseGroups[i].code}');
        }
      } else {
        print('   ⚠️  Use case вернул пустой список групп');
      }
    }
    
    print('\n✅ Диагностика завершена успешно!');
    
  } catch (e, stackTrace) {
    print('❌ Ошибка при диагностике: $e');
    print('Stack trace: $stackTrace');
  }
}