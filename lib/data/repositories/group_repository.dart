import 'package:my_mpt/data/datasources/remote/group_remote_datasource.dart';
import 'package:my_mpt/data/models/group.dart';
import 'package:my_mpt/data/repositories/specialty_repository.dart';
import 'package:my_mpt/domain/repositories/group_repository_interface.dart';

class GroupRepository implements GroupRepositoryInterface {
  final GroupRemoteDatasource _parserService = GroupRemoteDatasource();
  final SpecialtyRepository _specialtyRepository = SpecialtyRepository();

  @override
  Future<List<Group>> getGroupsBySpecialty(String specialtyCode) async {
    try {
      // Получаем имя специальности по коду из кэша специальностей
      final specialtyName = _specialtyRepository.getSpecialtyNameByCode(
        specialtyCode,
      );

      if (specialtyName == null) {
        // Если имя не найдено в кэше, загружаем специальности
        await _specialtyRepository.getSpecialties();
        // Повторно пробуем получить имя
        final retryName = _specialtyRepository.getSpecialtyNameByCode(
          specialtyCode,
        );
        if (retryName == null) {
          return [];
        }

        // Используем имя специальности для поиска групп
        final groupInfos = await _parserService.parseGroups(retryName);

        // Сортируем группы по заданному критерию
        groupInfos.sort((a, b) => _compareGroups(a, b));
        return groupInfos;
      }

      // Используем имя специальности для поиска групп
      final groupInfos = await _parserService.parseGroups(specialtyName);

      // Сортируем группы по заданному критерию
      groupInfos.sort((a, b) => _compareGroups(a, b));
      return groupInfos;
    } catch (e) {
      return [];
    }
  }

  /// Сравнивает две группы по заданному критерию:
  /// 1. Специальность (по возрастанию)
  /// 2. Год поступления (новые года выше)
  /// 3. Номер группы (по возрастанию)
  int _compareGroups(Group a, Group b) {
    // Извлекаем компоненты кода группы
    final componentsA = _parseGroupCode(a.code);
    final componentsB = _parseGroupCode(b.code);

    // Сравниваем по специальности (по возрастанию)
    final specialtyComparison = componentsA.specialty.compareTo(
      componentsB.specialty,
    );
    if (specialtyComparison != 0) {
      return specialtyComparison;
    }

    // Сравниваем по году поступления (новые года выше)
    final yearComparison = componentsB.year.compareTo(componentsA.year);
    if (yearComparison != 0) {
      return yearComparison;
    }

    // Сравниваем по номеру группы (по возрастанию)
    return componentsA.number.compareTo(componentsB.number);
  }

  /// Получает первую часть кода группы для составных названий
  String _getFirstGroupCode(String groupCode) {
    // Если есть разделители, берем первую часть
    final separators = [',', ';', '/'];
    for (final separator in separators) {
      final index = groupCode.indexOf(separator);
      if (index != -1) {
        return groupCode.substring(0, index).trim();
      }
    }
    // Если нет разделителей, возвращаем весь код
    return groupCode;
  }

  /// Извлекает компоненты из кода группы в формате Специальность-Номер-Год
  _GroupComponents _parseGroupCode(String groupCode) {
    // По умолчанию значения
    String specialty = '';
    int number = 0;
    int year = 0;

    try {
      // Для составных кодов используем только первую часть
      String firstPart = groupCode;
      final separators = [',', ';', '/'];
      for (final separator in separators) {
        final index = groupCode.indexOf(separator);
        if (index != -1) {
          firstPart = groupCode.substring(0, index).trim();
          break;
        }
      }

      // Разбиваем первую часть по дефису
      final parts = firstPart.split('-');
      if (parts.length >= 3) {
        specialty = parts[0]; // Специальность
        number = int.tryParse(parts[1]) ?? 0; // Номер группы
        year = int.tryParse(parts[2]) ?? 0; // Год поступления
      }
    } catch (e) {
      // В случае ошибки используем значения по умолчанию
    }

    return _GroupComponents(specialty, number, year);
  }
}

/// Вспомогательный класс для хранения компонентов кода группы
class _GroupComponents {
  final String specialty;
  final int number;
  final int year;

  _GroupComponents(this.specialty, this.number, this.year);
}
