import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/repositories/mpt_repository.dart';

/// Тест для проверки автоматического обновления после парсинга
void main() async {
  print('=== Тест автоматического обновления после парсинга ===');
  
  try {
    final parser = MptParserService();
    final repository = MptRepository();
    
    // Получаем список специальностей
    print('\n1. Получаем список специальностей...');
    final specialties = await repository.getSpecialties();
    print('   Найдено специальностей: ${specialties.length}');
    
    if (specialties.isNotEmpty) {
      print('   Первые 3 специальности:');
      for (int i = 0; i < specialties.length && i < 3; i++) {
        print('     ${specialties[i].code} - ${specialties[i].name}');
      }
      
      // Пробуем загрузить группы для первой специальности
      final firstSpecialty = specialties.first;
      print('\n2. Загружаем группы для специальности: ${firstSpecialty.code}');
      
      final startTime = DateTime.now();
      final groups = await repository.getGroupsBySpecialty(firstSpecialty.code);
      final endTime = DateTime.now();
      
      final duration = endTime.difference(startTime);
      print('   Загрузка заняла: ${duration.inMilliseconds} мс');
      print('   Найдено групп: ${groups.length}');
      
      if (groups.isNotEmpty) {
        print('   Первые 3 группы:');
        for (int i = 0; i < groups.length && i < 3; i++) {
          print('     ${groups[i].code}');
        }
      }
      
      // Проверим сортировку
      if (groups.length > 1) {
        bool isSorted = true;
        for (int i = 0; i < groups.length - 1; i++) {
          if (groups[i].code.compareTo(groups[i + 1].code) > 0) {
            isSorted = false;
            break;
          }
        }
        print('   Группы отсортированы: $isSorted');
      }
    }
    
    print('\n=== Тест завершен ===');
  } catch (e) {
    print('Ошибка в тесте: $e');
  }
}