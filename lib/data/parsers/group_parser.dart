import 'package:html/dom.dart';
import 'package:my_mpt/data/models/group.dart';

/// Парсер для извлечения информации о группах из HTML-документа
class GroupParser {
  /// Парсит список групп из HTML-документа с возможной фильтрацией по специальности
  ///
  /// Метод извлекает HTML-страницу с расписанием и находит все группы,
  /// при необходимости фильтруя их по коду специальности
  ///
  /// Параметры:
  /// - [document]: HTML-документ с расписанием
  /// - [specialtyFilter]: Опциональный фильтр по коду специальности
  ///
  /// Возвращает:
  /// Список информации о группах
  List<Group> parseGroups(Document document, [String? specialtyFilter]) {
    // Создаем список для хранения информации о группах
    final List<Group> groups = [];

    // Ищем все tabpanel элементы (более строгий селектор)
    final tabPanels = document.querySelectorAll('[role="tabpanel"]');

    // Проходим по всем tabpanel и ищем группы
    for (var tabPanel in tabPanels) {
      // Ищем заголовки групп только внутри tabpanel (строгий селектор h2, h3)
      final groupHeaders = tabPanel.querySelectorAll('h2, h3');

      // Ищем заголовок h2 с информацией о специальности
      String specialtyFromContext = '';
      for (var h2 in tabPanel.querySelectorAll('h2')) {
        final h2Text = h2.text.trim();
        if (h2Text.startsWith('Расписание занятий для ')) {
          specialtyFromContext = h2Text.substring(23).trim();
          break;
        }
      }

      // Проходим по заголовкам и парсим информацию о группах
      for (var header in groupHeaders) {
        final text = header.text.trim();
        // Проверяем, начинается ли текст строго с "Группа "
        if (text.startsWith('Группа ')) {
          // Парсим информацию о группе из текста заголовка
          final groupInfo = _parseGroupFromHeader(
            text,
            document,
            specialtyFromContext.isNotEmpty ? specialtyFromContext : null,
          );
          groups.addAll(groupInfo);
        }
      }
    }

    return groups;
  }

  /// Парсит информацию о группе из текста заголовка
  ///
  /// Метод извлекает информацию о группе из текста заголовка и определяет
  /// соответствующую специальность по префиксу кода группы
  ///
  /// Параметры:
  /// - [headerText]: Текст заголовка, содержащего информацию о группе
  /// - [document]: HTML-документ для извлечения дополнительной информации
  /// - [specialtyFromContext]: Опциональная информация о специальности из контекста
  ///
  /// Возвращает:
  /// Список информации о группах (обычно один элемент)
  List<Group> _parseGroupFromHeader(
    String headerText,
    Document document, [
    String? specialtyFromContext,
  ]) {
    // Создаем список для хранения информации о группах
    final List<Group> groups = [];

    try {
      // Извлекаем код группы из текста заголовка (например, "Группа Э-1-22, Э-11/1-23" -> "Э-1-22, Э-11/1-23")
      final groupCode = headerText.substring(7).trim();

      // Инициализируем переменные для хранения информации о специальности
      String specialtyCode = '';
      String specialtyName = '';

      // Если передана специальность из контекста, используем её
      if (specialtyFromContext != null && specialtyFromContext.isNotEmpty) {
        specialtyCode = specialtyFromContext;
        specialtyName = specialtyFromContext;
      } else {
        // Иначе определяем специальность по префиксу группы
        // Извлекаем префикс из первой части кода группы
        final groupCodeParts = groupCode.split(RegExp(r'[;,\/]'));
        String prefix = '';
        if (groupCodeParts.isNotEmpty) {
          final firstGroup = groupCodeParts[0].trim();
          // Извлекаем префикс из кода группы (например, ВД-2-23 -> ВД)
          final prefixMatch = RegExp(
            r'^([А-Яа-я0-9]+)-',
          ).firstMatch(firstGroup);
          if (prefixMatch != null) {
            prefix = prefixMatch.group(1) ?? '';
          }
        }

        // Маппинг префиксов групп к кодам специальностей
        final Map<String, String> prefixToSpecialtyCode = {
          'Э': '09.02.01 Э',
          'СА': '09.02.02 СА',
          'П': '09.02.07 П,Т',
          'Т': '09.02.07 П,Т',
          'ИС': '09.02.07 ИС, БД, ВД',
          'БД': '09.02.07 ИС, БД, ВД',
          'ВД': '09.02.07 ИС, БД, ВД',
          'БАС': '09.02.08 БАС',
          'БИ': '38.02.07 БИ',
          'Ю': '40.02.01 Ю',
          'ВТ': '09.02.07 ВТ',
        };

        // Маппинг префиксов групп к полным названиям специальностей
        final Map<String, String> prefixToSpecialtyName = {
          'Э': '09.02.01 Экономика и бухгалтерский учет',
          'СА': '09.02.02 Сети и системы связи',
          'П':
              '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'Т':
              '09.02.07 Прикладная информатика, Технологии дополненной и виртуальной реальности',
          'ИС':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БД':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'ВД':
              '09.02.07 Информационные системы и программирование, Базы данных, Веб-дизайн',
          'БАС': '09.02.08 Безопасность автоматизированных систем',
          'БИ': '38.02.07 Банковское дело',
          'Ю': '40.02.01 Право и организация социального обеспечения',
          'ВТ': '09.02.07 Веб-технологии',
        };

        // Определяем код и название специальности по префиксу
        if (prefixToSpecialtyCode.containsKey(prefix)) {
          specialtyCode = prefixToSpecialtyCode[prefix]!;
          specialtyName = prefixToSpecialtyName[prefix] ?? prefix;
        } else {
          // Если не удалось определить специальность по префиксу, используем префикс как код
          specialtyCode = prefix.isNotEmpty
              ? prefix
              : 'Неизвестная специальность';
          specialtyName = prefix.isNotEmpty
              ? prefix
              : 'Неизвестная специальность';
        }
      }

      // Добавляем информацию о группе в список
      groups.add(
        Group(
          code: groupCode, // Сохраняем полное название группы
          specialtyCode: specialtyCode,
          specialtyName: specialtyName,
        ),
      );
    } catch (e) {
      // В случае ошибки возвращаем пустой список
    }

    return groups;
  }
}
