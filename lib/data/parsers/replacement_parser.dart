import 'package:html/dom.dart';
import 'package:my_mpt/data/models/replacement.dart';
import 'package:my_mpt/data/parsers/mpt_parse_utils.dart';

/// Парсер для извлечения замен в расписании из HTML-документа
class ReplacementParser {
  /// Парсит замены в расписании для конкретной группы.
  ///
  /// Поведение сохраняем как сейчас: ищем замены только на сегодня и завтра.
  List<Replacement> parseScheduleChangesForGroup(
    Document document,
    String groupCode,
  ) {
    final List<Replacement> changes = [];

    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    final String todayDate =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';
    final String tomorrowDate =
        '${tomorrow.day.toString().padLeft(2, '0')}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';

    final normalizedGroupCode = normalizeGroupCode(groupCode);
    final groupCandidates = splitGroupCodes(groupCode);

    final dateHeaders = document.querySelectorAll('h4');
    final RegExp dateRegExp = RegExp(r'(\d{2}\.\d{2}\.\d{4})');

    for (var header in dateHeaders) {
      final text = header.text.trim();
      if (!text.startsWith('Замены на')) continue;

      final match = dateRegExp.firstMatch(text);
      if (match == null) continue;

      final currentDate = match.group(1)!;
      if (currentDate != todayDate && currentDate != tomorrowDate) continue;

      Element? nextElement = header.nextElementSibling;

      while (nextElement != null) {
        if (nextElement.localName == 'h4' &&
            nextElement.text.trim().startsWith('Замены на')) {
          break;
        }

        Element? table;
        if (nextElement.localName == 'div' &&
            nextElement.classes.contains('table-responsive')) {
          table = nextElement.querySelector('table.table');
        } else if (nextElement.localName == 'table' &&
            nextElement.classes.contains('table')) {
          table = nextElement;
        }

        if (table != null) {
          final caption = table.querySelector('caption');
          if (caption != null) {
            final captionText = normalizeGroupCode(caption.text);

            final matchGroup = (normalizedGroupCode.isNotEmpty &&
                    captionText.contains(normalizedGroupCode)) ||
                groupCandidates.any((c) => c.isNotEmpty && captionText.contains(c));

            if (matchGroup) {
              final rows = table.querySelectorAll('tbody > tr, tr:not(:first-child)');

              for (var row in rows) {
                final cells = row.querySelectorAll('td');
                if (cells.length == 4) {
                  changes.add(
                    Replacement(
                      lessonNumber: cells[0].text.trim(),
                      replaceFrom: cells[1].text.trim(),
                      replaceTo: cells[2].text.trim(),
                      updatedAt: cells[3].text.trim(),
                      changeDate: currentDate,
                    ),
                  );
                }
              }
            }
          }
        }

        nextElement = nextElement.nextElementSibling;
      }
    }

    return changes;
  }
}
