import 'dart:math';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:my_mpt/data/models/lesson.dart';

/// Отвечает за превращение HTML-ответа в структурированные данные расписания
///
/// Этот класс реализует парсинг HTML-страницы с расписанием и преобразование
/// данных в структурированный формат для дальнейшего использования в приложении
class ScheduleHtmlParser {
  /// Регулярное выражение для извлечения времени из текста
  static final RegExp _timePattern = RegExp(
    r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})',
  );

  /// Регулярное выражение для извлечения номера пары из текста
  static final RegExp _lessonNumberPattern = RegExp(r'\d+');

  /// Парсит HTML-страницу с расписанием и возвращает структурированные данные
  ///
  /// Метод находит вкладку соответствующей группы в HTML-документе,
  /// извлекает таблицы с расписанием по дням недели и преобразует
  /// их в структурированный формат
  ///
  /// Параметры:
  /// - [html]: HTML-страница с расписанием
  /// - [groupCode]: Код группы для которой нужно получить расписание
  ///
  /// Возвращает:
  /// - Map<String, List<Lesson>>: Расписание, где ключ - день недели, значение - список уроков
  Map<String, List<Lesson>> parse(String html, String groupCode) {
    // Парсим HTML-документ
    final document = html_parser.parse(html);
    // Находим вкладку для указанной группы
    final tabPane = _findTabPaneForGroup(document, groupCode);

    // Если вкладка не найдена, возвращаем пустое расписание
    if (tabPane == null) {
      return {};
    }

    // Создаем карту для хранения расписания по дням недели
    final schedule = <String, List<Lesson>>{};
    // Ищем все таблицы с расписанием в вкладке
    final tables = tabPane.children.where(
      (element) =>
          element.localName == 'table' && element.classes.contains('table'),
    );

    // Проходим по всем таблицам и парсим расписание
    for (final table in tables) {
      // Ищем заголовок таблицы с днем недели
      final header = table.querySelector('thead h4');
      if (header == null) continue;

      // Извлекаем день недели из заголовка
      final day = _extractDay(header);
      if (day.isEmpty) continue;

      // Извлекаем информацию о корпусе из заголовка
      final building = header.querySelector('span')?.text.trim() ?? '';
      // Парсим уроки из таблицы
      final lessons = _parseLessons(table, building);

      // Добавляем уроки в расписание, если они есть
      if (lessons.isNotEmpty) {
        schedule[day] = lessons;
      }
    }

    return schedule;
  }

  /// Находит вкладку для указанной группы в HTML-документе
  ///
  /// Метод ищет вкладку, соответствующую коду группы, в навигационном меню
  /// и возвращает соответствующий элемент tab-pane
  ///
  /// Параметры:
  /// - [document]: HTML-документ
  /// - [groupCode]: Код группы
  ///
  /// Возвращает:
  /// - Element?: Элемент tab-pane для группы или null, если не найден
  Element? _findTabPaneForGroup(Document document, String groupCode) {
    // Ищем все ссылки на вкладки в навигационном меню
    final tabLinks = document.querySelectorAll('ul.nav-tabs a');
    String? tabId;

    // Пробуем найти точное совпадение кода группы
    tabId ??= _findTabId(tabLinks, (text) => text == groupCode);
    // Если точное совпадение не найдено, ищем частичное совпадение
    tabId ??= _findTabId(tabLinks, (text) => text.contains(groupCode));

    // Если ID вкладки не найден, возвращаем null
    if (tabId == null) {
      return null;
    }

    // Возвращаем элемент tab-pane с найденным ID
    return document.querySelector('div[role="tabpanel"][id="$tabId"]');
  }

  /// Находит ID вкладки по условию
  ///
  /// Метод ищет ссылку на вкладку, удовлетворяющую указанному условию,
  /// и возвращает её ID
  ///
  /// Параметры:
  /// - [links]: Список ссылок на вкладки
  /// - [predicate]: Условие для поиска
  ///
  /// Возвращает:
  /// - String?: ID вкладки или null, если не найдена
  String? _findTabId(
    List<Element> links,
    bool Function(String text) predicate,
  ) {
    // Проходим по всем ссылкам
    for (final link in links) {
      // Извлекаем текст ссылки
      final text = link.text.trim();
      // Проверяем, удовлетворяет ли текст условию
      if (!predicate(text)) continue;

      // Извлекаем атрибут href
      final href = link.attributes['href'];
      // Если href начинается с #, возвращаем ID (без #)
      if (href != null && href.startsWith('#')) {
        return href.substring(1);
      }
    }
    return null;
  }

  /// Извлекает день недели из заголовка таблицы
  ///
  /// Метод извлекает текст дня недели из заголовка таблицы,
  /// преобразуя его в верхний регистр
  ///
  /// Параметры:
  /// - [header]: Заголовок таблицы
  ///
  /// Возвращает:
  /// - String: День недели в верхнем регистре
  String _extractDay(Element header) {
    // Пробуем извлечь текст из первого дочернего элемента
    final primaryText = header.nodes.isNotEmpty
        ? header.nodes.first.text?.trim() ?? ''
        : '';

    // Если текст найден, возвращаем его в верхнем регистре
    if (primaryText.isNotEmpty) {
      return primaryText.toUpperCase();
    }

    // В противном случае, извлекаем текст из заголовка и берем первое слово
    final fallback = header.text.trim();
    if (fallback.isEmpty) return '';

    return fallback.split(' ').first.toUpperCase();
  }

  /// Парсит уроки из таблицы
  ///
  /// Метод извлекает строки с уроками из таблицы и преобразует
  /// их в список объектов Lesson
  ///
  /// Параметры:
  /// - [table]: Таблица с расписанием
  /// - [building]: Корпус (извлекается из заголовка таблицы)
  ///
  /// Возвращает:
  /// - List<Lesson>: Список уроков
  List<Lesson> _parseLessons(Element table, String building) {
    // Создаем список для хранения уроков
    final lessons = <Lesson>[];
    // Извлекаем строки с уроками из таблицы
    final rows = _collectLessonRows(table);

    // Проходим по всем строкам и парсим уроки
    for (final row in rows) {
      lessons.addAll(_parseLessonRow(row, building));
    }

    return lessons;
  }

  /// Извлекает строки с уроками из таблицы
  ///
  /// Метод извлекает все строки из таблицы, пропуская
  /// первую (заголовок) и последнюю (пустую) строки
  ///
  /// Параметры:
  /// - [table]: Таблица с расписанием
  ///
  /// Возвращает:
  /// - List<Element>: Список строк с уроками
  List<Element> _collectLessonRows(Element table) {
    // Извлекаем все строки из таблицы
    final rows = table.getElementsByTagName('tr');
    // Если строк меньше или равно 2, возвращаем пустой список
    if (rows.length <= 2) return <Element>[];
    // Возвращаем строки, исключая первую и последнюю
    return rows.sublist(1, rows.length - 1);
  }

  /// Парсит строку с уроком
  ///
  /// Метод извлекает данные об уроке из строки таблицы
  /// и создает соответствующий объект Lesson
  ///
  /// Параметры:
  /// - [row]: Строка таблицы с уроком
  /// - [building]: Корпус
  ///
  /// Возвращает:
  /// - List<Lesson>: Список уроков (может содержать несколько для числителя/знаменателя)
  List<Lesson> _parseLessonRow(Element row, String building) {
    // Извлекаем ячейки из строки
    final cells = row.querySelectorAll('td');
    // Если ячеек не 3, возвращаем пустой список
    if (cells.length != 3) return <Lesson>[];

    // Извлекаем текст из первой ячейки (номер пары и время)
    final numberCellText = cells[0].text;
    // Извлекаем номер пары
    final number = _extractLessonNumber(numberCellText);
    // Извлекаем время начала и окончания
    final times = _parseTimeRange(numberCellText);

    // Если номер пары пустой, возвращаем пустой список
    if (number.isEmpty) return <Lesson>[];

    // Извлекаем ячейки с предметом и преподавателем
    final subjectCell = cells[1];
    final teacherCell = cells[2];

    // Ищем элементы с метками предметов и преподавателей (для числителя/знаменателя)
    final subjectLabels = subjectCell.querySelectorAll('div.label');
    final teacherLabels = teacherCell.querySelectorAll('div.label');

    // Если меток нет, парсим как обычный урок
    if (subjectLabels.isEmpty || teacherLabels.isEmpty) {
      final subject = subjectCell.text.trim();
      // Если предмет пустой, возвращаем пустой список
      if (subject.isEmpty) return <Lesson>[];

      // Создаем и возвращаем обычный урок
      return [
        Lesson(
          number: number,
          subject: subject,
          teacher: teacherCell.text.trim(),
          startTime: times.$1,
          endTime: times.$2,
          building: building,
          lessonType: null,
        ),
      ];
    }

    // Если есть метки, парсим как уроки с числителем/знаменателем
    final lessons = <Lesson>[];
    // Определяем количество пар меток
    final count = _pairedLabelsCount(subjectLabels, teacherLabels);

    // Проходим по всем парам меток
    for (var i = 0; i < count; i++) {
      final subjectText = subjectLabels[i].text.trim();
      // Если предмет пустой, пропускаем
      if (subjectText.isEmpty) continue;

      // Добавляем урок в список
      lessons.add(
        Lesson(
          number: number,
          subject: subjectText,
          teacher: teacherLabels[i].text.trim(),
          startTime: times.$1,
          endTime: times.$2,
          building: building,
          lessonType: _resolveLessonType(subjectLabels[i]),
        ),
      );
    }

    return lessons;
  }

  /// Извлекает номер пары из текста
  ///
  /// Метод извлекает номер пары из текста первой ячейки строки
  /// с помощью регулярного выражения
  ///
  /// Параметры:
  /// - [text]: Текст первой ячейки строки
  ///
  /// Возвращает:
  /// - String: Номер пары
  String _extractLessonNumber(String text) {
    // Ищем номер пары с помощью регулярного выражения
    final match = _lessonNumberPattern.firstMatch(text);
    // Возвращаем найденный номер или текст без пробелов
    return match?.group(0) ?? text.trim();
  }

  /// Извлекает время начала и окончания пары из текста
  ///
  /// Метод извлекает время начала и окончания пары из текста
  /// первой ячейки строки с помощью регулярного выражения
  ///
  /// Параметры:
  /// - [text]: Текст первой ячейки строки
  ///
  /// Возвращает:
  /// - (String, String): Кортеж из времени начала и окончания
  (String, String) _parseTimeRange(String text) {
    // Ищем время с помощью регулярного выражения
    final match = _timePattern.firstMatch(text);
    // Если не найдено, возвращаем пустые строки
    if (match == null) return ('', '');

    // Возвращаем время начала и окончания
    return (match.group(1)!, match.group(2)!);
  }

  /// Определяет тип пары (числитель/знаменатель) по метке
  ///
  /// Метод определяет тип пары по CSS-классам метки
  ///
  /// Параметры:
  /// - [label]: Элемент метки
  ///
  /// Возвращает:
  /// - String?: Тип пары ('numerator', 'denominator' или null)
  String? _resolveLessonType(Element label) {
    // Извлекаем CSS-классы метки
    final classes = label.attributes['class'] ?? '';
    // Определяем тип по классам
    if (classes.contains('label-danger')) return 'numerator';
    if (classes.contains('label-info')) return 'denominator';
    return null;
  }

  /// Определяет количество пар меток предметов и преподавателей
  ///
  /// Метод возвращает минимальное количество из двух списков меток
  ///
  /// Параметры:
  /// - [subjects]: Список меток предметов
  /// - [teachers]: Список меток преподавателей
  ///
  /// Возвращает:
  /// - int: Количество пар меток
  int _pairedLabelsCount(List<Element> subjects, List<Element> teachers) {
    // Если один из списков пуст, возвращаем 0
    if (subjects.isEmpty || teachers.isEmpty) return 0;
    // Возвращаем минимальное количество из двух списков
    return min(subjects.length, teachers.length);
  }
}
