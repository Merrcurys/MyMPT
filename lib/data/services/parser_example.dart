import 'package:my_mpt/data/services/mpt_parser_service.dart';

void main() async {
  // Create an instance of our parser service
  final parser = MptParserService();
  
  try {
    // Parse the tablist and extract href and aria-controls attributes
    final tabs = await parser.parseTabList();
    
    // Print the results
    print('Found ${tabs.length} tabs:');
    for (var tab in tabs) {
      print('Href: ${tab.href}, Aria-controls: ${tab.ariaControls}');
    }
  } catch (e) {
    print('Error: $e');
  }
}