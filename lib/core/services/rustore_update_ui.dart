import 'dart:io';

import 'package:flutter_rustore_update/flutter_rustore_update.dart';
import 'package:flutter_rustore_update/const.dart';

class RuStoreUpdateUi {
  static bool _started = false;
  static bool _listenerStarted = false;

  /// Полный in-app update flow с UI RuStore:
  /// - info()
  /// - если доступно: download() (UI RuStore)
  /// - слушаем listener(); когда DOWNLOADED -> completeUpdateFlexible() (UI RuStore)
  static Future<void> checkAndRunDeferredUpdate() async {
    if (!Platform.isAndroid) return;
    if (_started) return;
    _started = true;

    try {
      final info = await RustoreUpdateClient.info();

      // ВАЖНО: в SDK константа именно UPDATE_AILABILITY_AVAILABLE
      final updateAvailable =
          info.updateAvailability == UPDATE_AILABILITY_AVAILABLE;

      if (!updateAvailable) return;

      _ensureListener();

      // Если уже скачано (например, пользователь начал раньше) — сразу предлагаем установку
      if (info.installStatus == INSTALL_STATUS_DOWNLOADED) {
        await RustoreUpdateClient.completeUpdateFlexible();
        return;
      }

      // Отложенное обновление: скачивание с UI от RuStore
      await RustoreUpdateClient.download();
    } catch (_) {
      // По рекомендациям RuStore ошибки пользователю лучше не показывать
    }
  }

  static void _ensureListener() {
    if (_listenerStarted) return;
    _listenerStarted = true;

    // listener() нужен, чтобы поймать INSTALL_STATUS_DOWNLOADED
    RustoreUpdateClient.listener((value) async {
      try {
        if (value.installStatus == INSTALL_STATUS_DOWNLOADED) {
          // Установка обновления с UI RuStore
          await RustoreUpdateClient.completeUpdateFlexible();
        }
      } catch (_) {}
    });
  }
}
