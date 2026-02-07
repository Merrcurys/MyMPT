import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:my_mpt/data/models/lesson.dart';
import 'package:my_mpt/data/parsers/mpt_parse_utils.dart';

/// Парсер для извлечения расписания группы из HTML-документа
class ScheduleParser {
  /// Парсит HTML-страницу с расписанием и возвращает структурированные данные.
  ///
  /// Возвращает расписание, где ключ - день недели (в верхнем регистре),
  /// значение - список уроков.
  Map<String, List<Lesson>> parse(String html, String groupCode) {
    final document = html_parser.parse(html);

    final tabPane = _findTabPaneForGroup(document, groupCode);
    if (tabPane == null) return {};

    final schedule = <String, List<Lesson>>{};

    // Внутри tab-pane таблицы могут быть как прямыми детьми, так и вложенными.
    final tables = tabPane.querySelectorAll('table.table');

    for (final table in tables) {
      final header = table.querySelector('thead h4');
      if (header == null) continue;

      final day = _extractDay(header);
      if (day.isEmpty) continue;

      final building = header.querySelector('span')?.text.trim() ?? '';
      final lessons = _parseLessons(table, building);

      if (lessons.isNotEmpty) {
        schedule[day] = lessons;
      }
    }

    return schedule;
  }

  Element? _findTabPaneForGroup(Document document, String groupCode) {
    final group = normalizeGroupCode(groupCode);
    if (group.isEmpty) return null;

    // 1) Основной путь: вкладки групп
    final tabLinks = <Element>[]
      ..addAll(document.querySelectorAll('ul.nav-tabs a[href^="#"]'))
      ..addAll(document.querySelectorAll('a[data-toggle="tab"][href^="#"]'));

    String? tabId;

    for (final link in tabLinks) {
      final text = link.text.trim();
      if (groupMatchesTab(text, groupCode)) {
        final href = link.attributes['href'];
        if (href != null && href.startsWith('#')) {
          tabId = href.substring(1);
          break;
        }
      }
    }

    if (tabId == null || tabId.isEmpty) {
      // 2) Иногда табы могут быть без явного списка: пробуем найти tabpanel,
      // где в навигации встречается группа.
      return null;
    }

    return document.querySelector('[role="tabpanel"][id="$tabId"], #$tabId');
  }

  String _extractDay(Element header) {
    // Берём только текстовые ноды (чтобы не захватить корпус из <span>).
    final textNodes = header.nodes.where((n) => n.nodeType == Node.TEXT_NODE);
    final raw = textNodes.map((n) => n.text ?? '').join(' ').trim();

    final cleaned = raw.isNotEmpty ? raw : header.text.trim();
    if (cleaned.isEmpty) return '';

    // На странице день обычно идёт первым словом.
    return cleaned.split(RegExp(r'\s+')).first.toUpperCase();
  }

  List<Lesson> _parseLessons(Element table, String building) {
    final lessons = <Lesson>[];

    final rows = _collectLessonRows(table);
    for (final row in rows) {
      lessons.addAll(_parseLessonRow(row, building));
    }

    return lessons;
  }

  List<Element> _collectLessonRows(Element table) {
    final bodyRows = table.querySelectorAll('tbody > tr');
    if (bodyRows.isNotEmpty) return bodyRows;

    final rows = table.getElementsByTagName('tr');
    if (rows.length <= 2) return <Element>[];
    return rows.sublist(1, rows.length - 1);
  }

  List<Lesson> _parseLessonRow(Element row, String building) {
    final cells = row.querySelectorAll('td');
    if (cells.length < 3) return <Lesson>[];

    final numberCellText = cells[0].text;
    final number = _extractLessonNumber(numberCellText);
    final times = _parseTimeRange(numberCellText);

    if (number.isEmpty) return <Lesson>[];

    final subjectCell = cells[1];
    final teacherCell = cells[2];

    // Поддерживаем div.label и любые другие варианты (.label).
    final subjectLabels = subjectCell.querySelectorAll('.label');
    final teacherLabels = teacherCell.querySelectorAll('.label');

    if (subjectLabels.isEmpty || teacherLabels.isEmpty) {
      final subject = subjectCell.text.trim();
      if (subject.isEmpty) return <Lesson>[];

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

    final lessons = <Lesson>[];
    final count = _pairedLabelsCount(subjectLabels, teacherLabels);

    for (var i = 0; i < count; i++) {
      final subjectText = subjectLabels[i].text.trim();
      if (subjectText.isEmpty) continue;

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

  String _extractLessonNumber(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    return match?.group(0) ?? text.trim();
  }

  (String, String) _parseTimeRange(String text) {
    final match = RegExp(
      r'(\d{1,2}:\d{2})\s*[-–—]\s*(\d{1,2}:\d{2})',
    ).firstMatch(text);
    if (match == null) return ('', '');
    return (match.group(1)!, match.group(2)!);
  }

  String? _resolveLessonType(Element label) {
    final classes = label.attributes['class'] ?? '';

    // Старые bootstrap-классы на mpt.ru.
    if (classes.contains('label-danger')) return 'numerator';
    if (classes.contains('label-info')) return 'denominator';

    // На всякий: если будут новые классы.
    if (classes.contains('danger')) return 'numerator';
    if (classes.contains('info')) return 'denominator';

    return null;
  }

  int _pairedLabelsCount(List<Element> subjects, List<Element> teachers) {
    if (subjects.isEmpty || teachers.isEmpty) return 0;
    return subjects.length < teachers.length ? subjects.length : teachers.length;
  }
}
