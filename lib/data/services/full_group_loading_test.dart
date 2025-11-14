import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';
import 'package:my_mpt/domain/usecases/get_groups_by_specialty_usecase.dart';
import 'package:my_mpt/domain/entities/specialty.dart';

/// Полный тест загрузки групп через все слои
void main() async {
  print('=== Полный тест загрузки групп ===');
  
  try {
    // Сначала получим список специальностей, как это делает приложение
    print('\n1. Получаем список специальностей...');
    final parser = MptParserService();
    final tabs = await parser.parseTabList();
    print('   Найдено специальностей: ${tabs.length}');
    
    final specialties = tabs.map((tab) => _createSpecialtyFromTab(tab)).toList();
    print('   Создано специальностей: ${specialties.length}');
    
    if (specialties.isNotEmpty) {
      print('   Первые 3 специальности:');
      for (int i = 0; i < specialties.length && i < 3; i++) {
        print('     ${specialties[i].code} - ${specialties[i].name}');
      }
      
      // Протестируем загрузку групп для первой специальности
      final firstSpecialty = specialties.first;
      print('\n2. Тестируем загрузку групп для первой специальности:');
      print('   Код: ${firstSpecialty.code}');
      print('   Название: ${firstSpecialty.name}');
      
      // Используем репозиторий напрямую
      final repository = MptRepository();
      final groups = await repository.getGroupsBySpecialty(firstSpecialty.code);
      print('   Найдено групп: ${groups.length}');
      
      if (groups.isNotEmpty) {
        print('   Первые 3 группы:');
        for (int i = 0; i < groups.length && i < 3; i++) {
          print('     ${groups[i].code}');
        }
      }
      
      // Протестируем загрузку групп через use case
      print('\n3. Тестируем загрузку групп через use case:');
      final useCase = GetGroupsBySpecialtyUseCase(repository);
      final useCaseGroups = await useCase(firstSpecialty.code);
      print('   Use case вернул: ${useCaseGroups.length} групп');
      
      if (useCaseGroups.isNotEmpty) {
        print('   Первые 3 группы через use case:');
        for (int i = 0; i < useCaseGroups.length && i < 3; i++) {
          print('     ${useCaseGroups[i].code}');
        }
      }
      
      // Протестируем загрузку групп для хеша из таба
      print('\n4. Тестируем загрузку групп для хеша из таба:');
      final firstTabHref = tabs.first.href;
      print('   Хеш: $firstTabHref');
      
      final hashGroups = await repository.getGroupsBySpecialty(firstTabHref);
      print('   Найдено групп по хешу: ${hashGroups.length}');
      
      if (hashGroups.isNotEmpty) {
        print('   Первые 3 группы по хешу:');
        for (int i = 0; i < hashGroups.length && i < 3; i++) {
          print('     ${hashGroups[i].code}');
        }
      }
    }
    
    print('\n=== Полный тест загрузки групп завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
    print('Stack trace: $e');
  }
}

/// Create a Specialty object from tab information (дублируем логику из репозитория)
Specialty _createSpecialtyFromTab(dynamic tab) {
  // Extract specialty code from href attribute
  String code = tab.href;
  if (code.startsWith('#specialty-')) {
    code = code.substring(11).toUpperCase().replaceAll('-', '.').replaceAll('E', 'Э');
  }
  
  // Use the name from the tab text content
  String name = tab.name;
  if (name.isEmpty) {
    // Fallback to ariaControls if name is empty
    name = tab.ariaControls;
  }
  
  return Specialty(code: code, name: name);
}