import 'package:html/dom.dart';
import 'package:my_mpt/data/models/group.dart';

/// Парсер для извлечения информации о группах из HTML-документа
///
/// Исправлены проблемы с дублированием групп:
/// 1. Добавено удаление дубликатов по коду группы
/// 2. Улучшена обработка групп с несколькими кодами (разделенными запятыми/слэшами)
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

    // Если задан фильтр специальности, ищем только соответствующий tabpanel
    if (specialtyFilter != null && specialtyFilter.isNotEmpty) {
      // Ищем все tabpanel элементы (более строгий селектор)
      final tabPanels = document.querySelectorAll('[role="tabpanel"]');

      Element? targetTabPanel;
      // Ищем tabpanel элемент для заданной специальности (строгий селектор)
      for (var panel in tabPanels) {
        final h2Headers = panel.querySelectorAll('h2');
        for (var h2 in h2Headers) {
          final h2Text = h2.text.trim();
          if (h2Text.startsWith('Расписание занятий для ') &&
              (h2Text.contains(specialtyFilter) ||
                  specialtyFilter.contains(h2Text))) {
            targetTabPanel = panel;
            break;
          }
        }
        if (targetTabPanel != null) break;
      }

      // Если не нашли целевой tabpanel, используем первый доступный
      targetTabPanel ??= tabPanels.isNotEmpty ? tabPanels.first : null;

      if (targetTabPanel != null) {
        // Ищем заголовки групп только внутри целевого tabpanel (строгий селектор h2, h3)
        final groupHeaders = targetTabPanel.querySelectorAll('h2, h3');

        // Ищем заголовок h2 с информацией о специальности
        String specialtyFromContext = '';
        for (var h2 in targetTabPanel.querySelectorAll('h2')) {
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
    } else {
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
    }

    // Удаляем дубликаты групп, сравнивая по коду группы
    final uniqueGroups = <Group>[];
    final groupCodes = <String>{};

    for (var group in groups) {
      if (!groupCodes.contains(group.code)) {
        groupCodes.add(group.code);
        uniqueGroups.add(group);
      }
    }

    return uniqueGroups;
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
        // Извлекаем префикс из первой части кода группы (до первого разделителя)
        String prefix = '';

        // Находим первый разделитель (запятая, точка с запятой или слэш)
        final firstSeparatorIndex = groupCode.indexOf(RegExp(r'[;,\/]'));
        String firstGroupPart;

        if (firstSeparatorIndex != -1) {
          // Если есть разделитель, берем часть до него
          firstGroupPart = groupCode.substring(0, firstSeparatorIndex).trim();
        } else {
          // Если нет разделителей, берем весь код группы
          firstGroupPart = groupCode;
        }

        // Извлекаем префикс из первой части кода группы (например, ВД-2-23 -> ВД)
        final prefixMatch = RegExp(
          r'^([А-Яа-я0-9]+)-',
        ).firstMatch(firstGroupPart);

        if (prefixMatch != null) {
          prefix = prefixMatch.group(1) ?? '';
        }

        // Если не удалось определить специальность по префиксу, используем префикс как код
        specialtyCode = prefix.isNotEmpty
            ? prefix
            : 'Неизвестная специальность';
        specialtyName = prefix.isNotEmpty
            ? prefix
            : 'Неизвестная специальность';
      }

      // Добавляем информацию о группе в список
      // ВАЖНО: groupCode содержит полное название группы как есть, включая все разделители
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
