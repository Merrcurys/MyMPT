import 'package:my_mpt/data/services/mpt_parser_service.dart';

/// Example of how to use the MPT parser service
void main() async {
  // Create an instance of our parser service
  final parser = MptParserService();
  
  try {
    print('Parsing MPT schedule page...');
    
    // Parse the tablist and extract href and aria-controls attributes
    final tabs = await parser.parseTabList();
    
    // Print the results
    print('Found ${tabs.length} tabs:');
    for (var tab in tabs) {
      print('Href: ${tab.href}, Aria-controls: ${tab.ariaControls}');
    }
    
    print('\nParsing completed successfully!');
  } catch (e) {
    print('Error occurred while parsing: $e');
  }
}