import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeController {
  static const _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_key);
      mode.value = ThemeMode.values
          .firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
    } catch (_) {}
  }

  static Future<void> set(ThemeMode m) async {
    mode.value = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, m.name);
    } catch (_) {}
  }

  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      icon: const Icon(Icons.brightness_6),
      tooltip: 'Tema',
      onSelected: ThemeController.set,
      itemBuilder: (_) => const [
        PopupMenuItem(value: ThemeMode.system, child: Text('Ikuti sistem')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Terang')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
      ],
    );
  }
}