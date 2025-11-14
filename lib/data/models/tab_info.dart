/// Data class to hold tab information extracted from the MPT website
class TabInfo {
  final String href;
  final String ariaControls;
  final String name;
  
  TabInfo({required this.href, required this.ariaControls, required this.name});
  
  @override
  String toString() {
    return 'TabInfo(href: $href, ariaControls: $ariaControls, name: $name)';
  }
  
  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'ariaControls': ariaControls,
      'name': name,
    };
  }
}