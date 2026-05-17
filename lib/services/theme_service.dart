import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const _boxName = 'settings_box';
  static const _themeKey = 'theme_mode';
  static late Box<String> _box;
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    notifier.value = _load();
  }

  static ThemeMode _load() {
    final val = _box.get(_themeKey);
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static void setThemeMode(ThemeMode mode) {
    _box.put(_themeKey, mode.name);
    notifier.value = mode;
  }

  static ThemeMode next(ThemeMode current) {
    switch (current) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
    }
  }

  static IconData icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }
}
