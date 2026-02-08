import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsUtil {
  static const Map<String, String> _buildingToAddress = {
    'нежинская': 'Нежинская улица, 7, Москва',
    'нахимовский': 'Нахимовский проспект, 21, Москва',
  };

  static bool canOpenBuilding(String label) {
    final key = label.trim().toLowerCase();
    return _buildingToAddress.containsKey(key);
  }

  static Future<void> openBuilding(BuildContext context, String label) async {
    final key = label.trim().toLowerCase();
    final address = _buildingToAddress[key];
    if (address == null) return;

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть карты')),
      );
    }
  }
}
