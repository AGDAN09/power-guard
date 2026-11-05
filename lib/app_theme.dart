import 'package:flutter/material.dart';

//gak penting jir, cuma patokan
class AppColors {
  // mode gelap wok
  static const bg = Color(0xFF06060C);
  static const panel = Color(0xFF14141C);
  static const border = Color(0xFF23232E);
  static const cyan = Color(0xFF19D7E6);
  static const purple = Color(0xFFB35CFF);
  static const amber = Color(0xFFF5B800);
  static const green = Color(0xFF2ED573);
  static const red = Color(0xFFFF4757);
  static const muted = Color(0xFF8A8A99);

  // mode terang wok
  static const lightBg = Color(0xFFF4F6FA);
  static const lightPanel = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDDE1EA);
  static const lightCyan = Color(0xFF0097A7);
  static const lightMuted = Color(0xFF6B6F7B);
}

// warna mengikuti mode gelap atau terang
bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color bgColor(BuildContext c) => isDark(c) ? AppColors.bg : AppColors.lightBg;
Color panelColor(BuildContext c) =>
    isDark(c) ? AppColors.panel : AppColors.lightPanel;
Color borderColor(BuildContext c) =>
    isDark(c) ? AppColors.border : AppColors.lightBorder;
Color mutedColor(BuildContext c) =>
    isDark(c) ? AppColors.muted : AppColors.lightMuted;
Color accentColor(BuildContext c) =>
    isDark(c) ? AppColors.cyan : AppColors.lightCyan;

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.cyan,
    scaffoldBackgroundColor: AppColors.bg,
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.lightCyan,
    scaffoldBackgroundColor: AppColors.lightBg,
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: panelColor(context),
        //borderRadius: //BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
      ),
      child: child,
    );
  }
}

class GradientLine extends StatelessWidget {
  const GradientLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color.fromARGB(255, 255, 179, 92),
          accentColor(context),
        ]),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CircleIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor(context),
        border: Border.all(color: borderColor(context)),
      ),
      child: Icon(icon, color: color, size: size * 0.45),
    );
  }
}

/// Switch dengan warna tosca saat nyala
class NeonSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const NeonSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor(context)
            : (dark ? const Color(0xFF3A3A48) : const Color(0xFFB8BDC9)),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

String jarakLabel(int rssi) {
  if (rssi >= -55) return 'Sangat dekat';
  if (rssi >= -70) return 'Dekat';
  if (rssi >= -85) return 'Sedang';
  return 'Jauh';
}

Color jarakColor(int rssi) {
  if (rssi >= -70) return AppColors.green;
  if (rssi >= -85) return const Color.from(alpha: 1, red: 0.961, green: 0.722, blue: 0);
  return AppColors.red;
}