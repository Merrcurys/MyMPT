/// Модель информации о вкладке
///
/// Этот класс представляет собой информацию о вкладке
/// на странице расписания сайта техникума
class TabInfo {
  /// Атрибут href ссылки на вкладку
  final String href;

  /// Атрибут aria-controls вкладки
  final String ariaControls;

  /// Название вкладки
  final String name;

  /// Конструктор информации о вкладке
  ///
  /// Параметры:
  /// - [href]: Атрибут href ссылки на вкладку (обязательный)
  /// - [ariaControls]: Атрибут aria-controls вкладки (обязательный)
  /// - [name]: Название вкладки (обязательный)
  TabInfo({required this.href, required this.ariaControls, required this.name});

  @override
  String toString() {
    return 'TabInfo(href: $href, ariaControls: $ariaControls, name: $name)';
  }

  /// Преобразует объект информации о вкладке в JSON
  ///
  /// Возвращает:
  /// - Map<String, dynamic>: Представление информации о вкладке в формате JSON
  Map<String, dynamic> toJson() {
    return {'href': href, 'ariaControls': ariaControls, 'name': name};
  }
}
