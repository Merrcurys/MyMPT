import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class UpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check_date';
  static const String _ignoredVersionKey = 'ignored_update_version';
  static const Duration _checkInterval = Duration(hours: 24); // Check once per day
  
  // RuStore app page URL
  static const String _appStoreUrl = 'https://www.rustore.ru/catalog/app/ru.merrcurys.my_mpt';

  /// Check if there's a new version available
  Future<bool> isNewVersionAvailable() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Get last checked date
      final prefs = await SharedPreferences.getInstance();
      final lastCheckString = prefs.getString(_lastUpdateCheckKey);
      
      // Check if we should perform a new check based on the interval
      if (lastCheckString != null) {
        try {
          final lastCheck = DateTime.parse(lastCheckString);
          final now = DateTime.now();
          
          if (now.difference(lastCheck) < _checkInterval) {
            // Don't check again yet
            return false;
          }
        } catch (e) {
          // If there's an error parsing the date, continue with the check
        }
      }
      
      // Update the last check date
      await prefs.setString(_lastUpdateCheckKey, DateTime.now().toIso8601String());
      
      // Get the version that was ignored (if any)
      final ignoredVersion = prefs.getString(_ignoredVersionKey);
      if (ignoredVersion == currentVersion) {
        return false; // User already ignored this version
      }
      
      // Fetch the latest version from RuStore
      final latestVersion = await _fetchLatestVersionFromRuStore();
      
      if (latestVersion != null && _isNewerVersion(latestVersion, currentVersion)) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking for updates: $e');
      return false;
    }
  }
  
  /// Fetch the latest version from RuStore by scraping the page
  Future<String?> _fetchLatestVersionFromRuStore() async {
    try {
      final response = await http.get(
        Uri.parse(_appStoreUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
      );
      
      if (response.statusCode == 200) {
        // Extract version from the meta description
        final descriptionRegex = RegExp(r'Официальная версия \(([\d.]+)\)');
        final descriptionMatch = descriptionRegex.firstMatch(response.body);
        
        if (descriptionMatch != null && descriptionMatch.groupCount > 0) {
          final version = descriptionMatch.group(1);
          if (version != null && _isValidVersion(version)) {
            return version;
          }
        }
        
        // Alternative: Look for version in title tag
        final titleRegex = RegExp(r'Android ([\d.]+)');
        final titleMatch = titleRegex.firstMatch(response.body);
        
        if (titleMatch != null && titleMatch.groupCount > 0) {
          final version = titleMatch.group(1);
          if (version != null && _isValidVersion(version)) {
            return version;
          }
        }
        
        // Fallback: Parse as HTML document and look for version information
        final document = parser.parse(response.body);
        
        // Look for version information in the page
        // This selector might need to be updated based on the actual RuStore page structure
        final versionElements = document.querySelectorAll('div.app-version, span.version, .app-info__version, [data-version]');
        
        for (final element in versionElements) {
          final text = element.text.trim();
          if (_isValidVersion(text)) {
            return text;
          }
        }
        
        // Alternative: Look for version in script tags or meta tags
        final scriptElements = document.querySelectorAll('script');
        for (final script in scriptElements) {
          if (script.text.contains('version') || script.text.contains('Version')) {
            // Extract version using regex
            final versionRegex = RegExp(r'v?(\d+\.\d+\.\d+)', caseSensitive: false);
            final match = versionRegex.firstMatch(script.text);
            if (match != null) {
              return match.group(1);
            }
          }
        }
        
        // If not found in script tags, try meta tags
        final metaElements = document.querySelectorAll('meta');
        for (final meta in metaElements) {
          final content = meta.attributes['content'];
          final name = meta.attributes['name'] ?? meta.attributes['property'];
          
          if (content != null && name != null && 
              (name.contains('version') || name.contains('Version'))) {
            if (_isValidVersion(content)) {
              return content;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching version from RuStore: $e');
    }
    
    return null;
  }
  
  /// Check if the version string is valid (contains numbers and dots)
  bool _isValidVersion(String version) {
    // Version should match pattern like "x.y.z" or "x.y.z.a"
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+(\.\d+)?$');
    return versionRegex.hasMatch(version);
  }
  
  /// Compare two version strings to determine if newVersion is newer than currentVersion
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      // Split version strings into parts
      final newParts = newVersion.split('.');
      final currentParts = currentVersion.split('.');
      
      // Compare each part numerically
      for (int i = 0; i < newParts.length; i++) {
        if (i >= currentParts.length) {
          // New version has more parts (e.g., 1.2.3.4 vs 1.2.3) - consider newer
          return true;
        }
        
        final newNum = int.tryParse(newParts[i]) ?? 0;
        final currentNum = int.tryParse(currentParts[i]) ?? 0;
        
        if (newNum > currentNum) {
          return true;
        } else if (newNum < currentNum) {
          return false;
        }
        // If equal, continue to next part
      }
      
      // If all compared parts are equal and current has more parts, it's not newer
      return currentParts.length < newParts.length;
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
  
  /// Open the app store page
  Future<void> openAppStore() async {
    final Uri url = Uri.parse(_appStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch RuStore URL');
    }
  }
  
  /// Mark a version as ignored
  Future<void> ignoreUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredVersionKey, packageInfo.version);
  }
  
  /// Clear the ignored version (for testing purposes)
  Future<void> clearIgnoredVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ignoredVersionKey);
  }
}