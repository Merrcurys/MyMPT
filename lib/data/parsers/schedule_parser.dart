import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:my_mpt/data/models/lesson.dart';
import 'package:my_mpt/data/parsers/mpt_parse_utils.dart';

/// Парсер для извлечения расписания группы из HTML-документа.
///
/// Основной путь: вкладки групп (nav-tabs).
/// Fallback: сканирование DOM (как в Kotlin-версии), если вкладка не найдена.
class ScheduleParser {
  static const List<String> _daysOrder = <String>[
    'ПОНЕДЕЛЬНИК',
    'ВТОРНИК',
    'СРЕДА',
    'ЧЕТВЕРГ',
    'ПЯТНИЦА',
    'СУББОТА',
    'ВОСКРЕСЕНЬЕ',
  ];

  /// Парсит HTML-страницу с расписанием и возвращает структурированные данные.
  ///
  /// Возвращает расписание, где ключ - день недели (в верхнем регистре),
  /// значение - список уроков.
  Map<String, List<Lesson>> parse(String html, String groupCode) {
    final document = html_parser.parse(html);

    final tabPane = _findTabPaneForGroup(document, groupCode);
    if (tabPane != null) {
      return _parseFromContainer(tabPane);
    }

    // Fallback (Kotlin-like): ищем блок группы в документе и идём по соседям.
    return _parseByScanningDocument(document, groupCode);
  }

  Map<String, List<Lesson>> _parseFromContainer(Element container) {
    final schedule = <String, List<Lesson>>{};

    final tables = container.querySelectorAll('table.table');

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

  Map<String, List<Lesson>> _parseByScanningDocument(
    Document document,
    String groupCode,
  ) {
    final schedule = <String, List<Lesson>>{};

    final normalizedGroup = normalizeGroupCode(groupCode);
    if (normalizedGroup.isEmpty) return {};

    final header = _findElementContainingOwnText(document, normalizedGroup);
    if (header == null) return {};

    String currentDay = '';
    String currentBuilding = '';

    Element? el = header.nextElementSibling;

    while (el != null) {
      final text = el.text.trim();

      // Стоп-условия, похожие на Kotlin: следующий заголовок группы/специальности.
      final upper = text.toUpperCase();
      if (upper.startsWith('ГРУППА ') ||
          upper.startsWith('РАСПИСАНИЕ ЗАНЯТИЙ ДЛЯ')) {
        break;
      }

      // Обновляем текущий день/корпус, если встретили строку дня.
      final dayMatch = _daysOrder.firstWhere(
        (d) => upper.startsWith(d),
        orElse: () => '',
      );
      if (dayMatch.isNotEmpty) {
        currentDay = dayMatch;
        currentBuilding = _extractBuildingFromDayLine(text, dayMatch);
      }

      if (el.localName == 'table' && el.classes.contains('table')) {
        if (currentDay.isNotEmpty) {
          final lessons = _parseLessons(el, currentBuilding);
          if (lessons.isNotEmpty) {
            schedule[currentDay] = lessons;
          }
        }
      } else {
        // Иногда таблица может быть внутри контейнера.
        final tables = el.querySelectorAll('table.table');
        if (tables.isNotEmpty && currentDay.isNotEmpty) {
          for (final t in tables) {
            final lessons = _parseLessons(t, currentBuilding);
            if (lessons.isNotEmpty) {
              schedule[currentDay] = lessons;
            }
          }
        }
      }

      el = el.nextElementSibling;
    }

    return schedule;
  }

  String _extractBuildingFromDayLine(String raw, String dayMatch) {
    final after = raw.substring(dayMatch.length).trim();
    if (after.isEmpty) return '';

    // Берём первую смысловую часть и убираем пунктуацию.
    final first = after.split(RegExp(r'[,.(]|\s{2,}')).first.trim();
    return first.replaceAll(RegExp(r'^[,.(\s]+|[,.)\s]+$'), '').trim();
  }

  Element? _findTabPaneForGroup(Document document, String groupCode) {
    final group = normalizeGroupCode(groupCode);
    if (group.isEmpty) return null;

    final tabLinks = <Element>[
      ...document.querySelectorAll('ul.nav-tabs a[href^="#"]'),
      ...document.querySelectorAll('a[data-toggle="tab"][href^="#"]'),
    ];

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

    if (tabId == null || tabId.isEmpty) return null;

    return document.querySelector('[role="tabpanel"][id="$tabId"], #$tabId');
  }

  Element? _findElementContainingOwnText(Document document, String normalizedNeedle) {
    // Чаще всего код группы лежит в заголовках/ссылках.
    final candidates = document.querySelectorAll('h1,h2,h3,h4,a,div,p,span');

    for (final el in candidates) {
      final own = _ownText(el);
      if (own.isEmpty) continue;
      final normalizedOwn = normalizeGroupCode(own);
      if (normalizedOwn.contains(normalizedNeedle)) return el;
    }

    // На всякий случай — полный обход.
    for (final el in document.querySelectorAll('*')) {
      final own = _ownText(el);
      if (own.isEmpty) continue;
      final normalizedOwn = normalizeGroupCode(own);
      if (normalizedOwn.contains(normalizedNeedle)) return el;
    }

    return null;
  }

  String _ownText(Element el) {
    final buffer = StringBuffer();
    for (final n in el.nodes) {
      if (n.nodeType == Node.TEXT_NODE) {
        final t = n.text ?? '';
        final trimmed = t.trim();
        if (trimmed.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(trimmed);
        }
      }
    }
    return buffer.toString().trim();
  }

  String _extractDay(Element header) {
    final textNodes = header.nodes.where((n) => n.nodeType == Node.TEXT_NODE);
    final raw = textNodes.map((n) => n.text ?? '').join(' ').trim();

    final cleaned = raw.isNotEmpty ? raw : header.text.trim();
    if (cleaned.isEmpty) return '';

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

    // 1) Вариант с label'ами (bootstrap): сохраняем старую логику.
    final subjectLabels = subjectCell.querySelectorAll('.label');
    final teacherLabels = teacherCell.querySelectorAll('.label');

    if (subjectLabels.isNotEmpty && teacherLabels.isNotEmpty) {
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

    // 2) Kotlin-like: извлекаем до 2 частей по <br> / детям.
    final subjectParts = _extractParts(subjectCell);
    final teacherParts = _extractParts(teacherCell);

    // Если у нас 2 части (числ/знам) — отдаём 2 урока с lessonType.
    if (subjectParts.length >= 2 || teacherParts.length >= 2) {
      final s0 = subjectParts.isNotEmpty ? subjectParts[0] : '';
      final s1 = subjectParts.length >= 2 ? subjectParts[1] : '';
      final t0 = teacherParts.isNotEmpty ? teacherParts[0] : '';
      final t1 = teacherParts.length >= 2 ? teacherParts[1] : '';

      final out = <Lesson>[];

      if (s0.trim().isNotEmpty || t0.trim().isNotEmpty) {
        out.add(
          Lesson(
            number: number,
            subject: s0.trim(),
            teacher: t0.trim(),
            startTime: times.$1,
            endTime: times.$2,
            building: building,
            lessonType: 'numerator',
          ),
        );
      }

      if (s1.trim().isNotEmpty || t1.trim().isNotEmpty) {
        out.add(
          Lesson(
            number: number,
            subject: s1.trim(),
            teacher: t1.trim(),
            startTime: times.$1,
            endTime: times.$2,
            building: building,
            lessonType: 'denominator',
          ),
        );
      }

      return out;
    }

    // 3) Обычная пара.
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

  List<String> _extractParts(Element td) {
    final parts = <String>[];

    // 1) Если есть 2 явных child-ноды (как в Kotlin), берём их.
    if (td.children.length == 2) {
      for (final child in td.children) {
        final t = child.text.trim();
        if (t.isNotEmpty) parts.add(t);
      }
      if (parts.isNotEmpty) return parts.take(2).toList(growable: false);
    }

    // 2) Пытаемся распилить по <br> в HTML.
    final html = td.innerHtml;
    final brSplit = html.split(RegExp(r'<br\s*/?>', caseSensitive: false));
    final brParts = brSplit
        .map((s) => (html_parser.parseFragment(s).text ?? '').trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (brParts.isNotEmpty) {
      return brParts.take(2).toList(growable: false);
    }

    // 3) Fallback — весь текст.
    final text = td.text.trim();
    return text.isNotEmpty ? <String>[text] : <String>[];
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

    if (classes.contains('label-danger')) return 'numerator';
    if (classes.contains('label-info')) return 'denominator';

    if (classes.contains('danger')) return 'numerator';
    if (classes.contains('info')) return 'denominator';

    return null;
  }

  int _pairedLabelsCount(List<Element> subjects, List<Element> teachers) {
    if (subjects.isEmpty || teachers.isEmpty) return 0;
    return subjects.length < teachers.length ? subjects.length : teachers.length;
  }
}
