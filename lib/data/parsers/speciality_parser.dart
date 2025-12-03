import 'package:html/dom.dart';

/// Парсер для извлечения списка вкладок специальностей из HTML-документа
class SpecialityParser {
  /// Парсит список вкладок специальностей из HTML-документа
  ///
  /// Метод находит навигационное меню со списком вкладок и извлекает
  /// информацию о каждой вкладке
  ///
  /// Параметры:
  /// - [document]: HTML-документ с расписанием
  ///
  /// Возвращает:
  /// Список информации о вкладках специальностей в виде Map
  List<Map<String, String>> parse(Document document) {
    // Ищем элемент навигационного меню со списком вкладок (более строгий селектор)
    final tablist = document.querySelector('ul[role="tablist"]');

    // Проверяем наличие элемента
    if (tablist == null) {
      throw Exception('Элемент навигационного меню не найден на странице');
    }

    // Ищем все элементы вкладок в навигационном меню (строгий селектор)
    final tabItems = tablist.querySelectorAll(
      'li[role="presentation"] > a[href^="#"]',
    );

    // Создаем список для хранения информации о вкладках
    final List<Map<String, String>> tabs = [];

    // Проходим по всем вкладкам и извлекаем информацию
    for (var anchor in tabItems) {
      // Извлекаем атрибуты ссылки
      final href = anchor.attributes['href'];
      final ariaControls = anchor.attributes['aria-controls'];
      final name = anchor.text.trim();

      // Добавляем информацию о вкладке в список, если есть необходимые атрибуты
      if (href != null &&
          href.startsWith('#') &&
          ariaControls != null &&
          name.isNotEmpty) {
        tabs.add({'href': href, 'ariaControls': ariaControls, 'name': name});
      }
    }

    return tabs;
  }
}
