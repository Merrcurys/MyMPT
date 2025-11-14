# MPT Website Parser

This parser extracts href and aria-controls attributes from the tablist on the MPT schedule page (https://mpt.ru/raspisanie/).

## Features

- Parses the MPT schedule website
- Extracts tab information from the tablist
- Retrieves href and aria-controls attributes from each tab

## Usage

1. Import the parser service:
```dart
import 'package:my_mpt/data/services/mpt_parser_service.dart';
```

2. Create an instance of the parser:
```dart
final parser = MptParserService();
```

3. Parse the tablist:
```dart
final tabs = await parser.parseTabList();
```

4. Access the extracted information:
```dart
for (var tab in tabs) {
  print('Href: ${tab.href}, Aria-controls: ${tab.ariaControls}');
}
```

## Classes

### MptParserService
Main service class for parsing the MPT website.

#### Methods
- `parseTabList()`: Returns a Future<List<TabInfo>> with the parsed tab information.

### TabInfo
Data class holding the parsed information from each tab.

#### Properties
- `href`: The href attribute of the tab anchor element
- `ariaControls`: The aria-controls attribute of the tab anchor element

## Dependencies

- http: For making HTTP requests to fetch the webpage
- html: For parsing the HTML content

## Example

See `parser_usage_example.dart` for a complete working example.