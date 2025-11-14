import 'package:my_mpt/data/services/mpt_parser_service.dart';
import 'package:my_mpt/data/models/tab_info.dart';
import 'package:my_mpt/data/models/group_info.dart';
import 'package:my_mpt/domain/repositories/specialty_repository_interface.dart';
import 'package:my_mpt/domain/entities/specialty.dart';
import 'package:my_mpt/domain/entities/group.dart';

class MptRepository implements SpecialtyRepositoryInterface {
  final MptParserService _parserService = MptParserService();
  
  /// Get specialties by parsing the MPT website
  @override
  Future<List<Specialty>> getSpecialties() async {
    try {
      final tabs = await _parserService.parseTabList();
      // Extract specialty names from href attributes
      final specialties = tabs.map((tab) => _createSpecialtyFromTab(tab)).toList();
      
      // Sort specialties by name
      specialties.sort((a, b) => a.name.compareTo(b.name));
      
      return specialties;
    } catch (e) {
      // Return empty list or handle error as appropriate
      return [];
    }
  }
  
  /// Get groups by specialty code
  @override
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      print('DEBUG: Запрашиваем группы для специальности: $specialtyCode');
      print('DEBUG: Длина кода специальности: ${specialtyCode.length}');
      print('DEBUG: Код специальности в байтах: ${specialtyCode.codeUnits}');
      
      // Получаем список всех табов для создания маппинга между хешами и кодами специальностей
      final parserService = MptParserService();
      final tabs = await parserService.parseTabList();
      print('DEBUG: Получено табов: ${tabs.length}');
      
      // Создаем маппинг между хешами и кодами специальностей
      final Map<String, String> hashToSpecialtyCode = {};
      final Map<String, String> hashToSpecialtyName = {};
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
          // используем код специальности из имени таба
          specialtyCodeFromHref = tab.name;
        }
        
        // Маппинг: хеш -> код специальности
        hashToSpecialtyCode[tab.href] = specialtyCodeFromHref;
        hashToSpecialtyName[tab.href] = tab.name;
        print('DEBUG: Маппинг: ${tab.href} -> $specialtyCodeFromHref (name: ${tab.name})');
      }
      
      // Если specialtyCode - это хеш, заменяем его на реальный код специальности
      String actualSpecialtyCode = specialtyCode;
      String actualSpecialtyName = '';
      if (specialtyCode.startsWith('#') && hashToSpecialtyCode.containsKey(specialtyCode)) {
        actualSpecialtyCode = hashToSpecialtyCode[specialtyCode]!;
        actualSpecialtyName = hashToSpecialtyName[specialtyCode] ?? '';
        print('DEBUG: Заменяем хеш $specialtyCode на код специальности: $actualSpecialtyCode (name: $actualSpecialtyName)');
      }
      
      final groupInfos = await parserService.parseGroups();
      print('DEBUG: Получено групп от парсера: ${groupInfos.length}');
      
      if (groupInfos.isNotEmpty) {
        print('DEBUG: Первая группа: ${groupInfos.first.code} (специальность: "${groupInfos.first.specialtyCode}")');
        print('DEBUG: Сравнение с "$actualSpecialtyCode":');
        print('  contains(specialtyCode): ${groupInfos.first.specialtyCode.contains(actualSpecialtyCode)}');
        print('  contains(specialtyName): ${groupInfos.first.specialtyName.contains(actualSpecialtyCode)}');
        
        // Дополнительная отладка для всех групп
        for (int i = 0; i < groupInfos.length && i < 5; i++) {
          print('DEBUG: Группа $i: ${groupInfos[i].code} (специальность: "${groupInfos[i].specialtyCode}")');
          print('  Содержит "$actualSpecialtyCode" в коде: ${groupInfos[i].specialtyCode.contains(actualSpecialtyCode)}');
          print('  Содержит "$actualSpecialtyCode" в названии: ${groupInfos[i].specialtyName.contains(actualSpecialtyCode)}');
        }
      }
      
      // Filter groups by specialty code
      final filteredGroups = groupInfos.where((groupInfo) {
        // Проверяем точное совпадение кодов специальностей
        final exactCodeMatch = groupInfo.specialtyCode == actualSpecialtyCode;
        
        // Также проверяем, содержит ли код специальности группы искомый код (для частичных совпадений)
        final containsCode = groupInfo.specialtyCode.contains(actualSpecialtyCode);
        
        // Для хешей проверяем маппинг
        bool hashMatch = false;
        if (actualSpecialtyCode.startsWith('#specialty-')) {
          // Преобразуем хеш в код специальности
          String mappedCode = actualSpecialtyCode.substring(11)
              .toUpperCase()
              .replaceAll('-', '.')
              .replaceAll('E', 'Э')
              .replaceAll('P', 'П')
              .replaceAll('T', 'Т')
              .replaceAll('IS', 'ИС')
              .replaceAll('BD', 'БД')
              .replaceAll('VD', 'ВД');
          
          hashMatch = groupInfo.specialtyCode.contains(mappedCode);
          print('DEBUG: Проверка хеша типа specialty: "$actualSpecialtyCode" -> "$mappedCode"');
        } else if (actualSpecialtyCode.startsWith('#')) {
          // Для хешей типа #942c7895202110541adecebcd7f18dd7
          // проверяем по названию специальности
          hashMatch = groupInfo.specialtyCode == actualSpecialtyName || 
                     groupInfo.specialtyName.contains(actualSpecialtyName);
          print('DEBUG: Проверка хеша типа ID: "$actualSpecialtyCode" -> "$actualSpecialtyName"');
        }
        
        print('DEBUG: Фильтрация группы "${groupInfo.code}":');
        print('  Специальность группы: "${groupInfo.specialtyCode}"');
        print('  Искомая специальность: "$actualSpecialtyCode"');
        print('  Искомое имя специальности: "$actualSpecialtyName"');
        print('  Точное совпадение кодов: $exactCodeMatch');
        print('  Содержит код: $containsCode');
        print('  Совпадение по хешу: $hashMatch');
        
        return exactCodeMatch || containsCode || hashMatch;
      }).toList();
      
      print('DEBUG: Отфильтровано групп: ${filteredGroups.length}');
      
      if (filteredGroups.isNotEmpty) {
        print('DEBUG: Первая отфильтрованная группа: ${filteredGroups.first.code}');
      }
      
      // Convert GroupInfo to Group entities
      final result = filteredGroups.map((groupInfo) => 
        Group(code: groupInfo.code, specialtyCode: groupInfo.specialtyCode)
      ).toList();
      
      // Sort groups by code
      result.sort((a, b) => a.code.compareTo(b.code));
      
      print('DEBUG: Возвращаем ${result.length} групп');
      return result;
    } catch (e) {
      print('DEBUG: Ошибка получения групп: $e');
      // Return empty list or handle error as appropriate
      return [];
    }
  }
  
  /// Create a Specialty object from tab information
  Specialty _createSpecialtyFromTab(TabInfo tab) {
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
}