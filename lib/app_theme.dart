import 'package:flutter/material.dart';

//gak penting jir, cuma patokan
class AppColors {
  // mode gelap wok (neon, nggak diubah)
  static const bg = Color(0xFF06060C);
  static const panel = Color(0xFF14141C);
  static const border = Color(0xFF23232E);
  static const cyan = Color(0xFF19D7E6);
  static const purple = Color(0xFFB35CFF);
  static const amber = Color(0xFFF5B800);
  static const green = Color(0xFF2ED573);
  static const red = Color(0xFFFF4757);
  static const muted = Color(0xFF8A8A99);

  // mode terang wok: krem hangat, bersih, aksen terakota
  // (semua warna teks sudah dicek kontrasnya >= 4.5:1 di atas panel putih)
  static const lightBg = Color(0xFFFAF6F0); // krem
  static const lightPanel = Color(0xFFFFFEFB); // putih hangat
  static const lightBorder = Color(0xFFEBE3D8); // garis tipis krem
  static const lightText = Color(0xFF2B2420); // cokelat tua, bukan hitam pekat
  static const lightMuted = Color(0xFF766B61); // abu cokelat
  static const lightAccent = Color(0xFFB9552B); // terakota
  static const lightGreen = Color(0xFF357F50); // hijau sage
  static const lightRed = Color(0xFFC73A4B); // merah mawar, beda dari terakota
  static const lightAmber = Color(0xFF9A6700); // kuning emas gelap
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
    isDark(c) ? AppColors.cyan : AppColors.lightAccent;

// warna status (aman / bahaya / peringatan) dan teks di atas warna aksen
Color okColor(BuildContext c) =>
    isDark(c) ? AppColors.green : AppColors.lightGreen;
Color dangerColor(BuildContext c) =>
    isDark(c) ? AppColors.red : AppColors.lightRed;
Color warnColor(BuildContext c) =>
    isDark(c) ? AppColors.amber : AppColors.lightAmber;
Color onAccentColor(BuildContext c) => isDark(c) ? Colors.black : Colors.white;

// gelap = siku-siku (tegas), terang = membulat (lembut)
BorderRadius cornerRadius(BuildContext c, [double r = 16]) =>
    isDark(c) ? BorderRadius.zero : BorderRadius.circular(r);

// bayangan tipis hangat, cuma dipakai di mode terang
const List<BoxShadow> kSoftShadow = [
  BoxShadow(
    color: Color(0x145A3E2B),
    blurRadius: 16,
    offset: Offset(0, 4),
  ),
];

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.cyan,
    scaffoldBackgroundColor: AppColors.bg,
  );
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.lightAccent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.lightAccent,
    onPrimary: Colors.white,
    surface: AppColors.lightBg,
    onSurface: AppColors.lightText,
    onSurfaceVariant: AppColors.lightMuted,
    outline: AppColors.lightMuted,
    outlineVariant: AppColors.lightBorder,
    inverseSurface: AppColors.lightText,
    onInverseSurface: AppColors.lightBg,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBg,
    dividerColor: AppColors.lightBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.lightText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.lightPanel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
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
        borderRadius: cornerRadius(context),
        border: Border.all(color: borderColor(context)),
        boxShadow: isDark(context) ? null : kSoftShadow,
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
        gradient: LinearGradient(
          colors: isDark(context)
              ? [
                  const Color.fromARGB(255, 255, 179, 92),
                  accentColor(context),
                ]
              : const [
                  Color(0xFFF0B27A), // peach
                  AppColors.lightAccent,
                ],
        ),
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
    final dark = isDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // terang: latar tipis sewarna ikon, lebih lembut daripada cincin kosong
        color: dark ? bgColor(context) : color.withValues(alpha: 0.10),
        border: Border.all(
          color: dark ? borderColor(context) : color.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.45),
    );
  }
}

/// Switch dengan warna tosca saat nyala (terakota di mode terang)
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
            : (dark ? const Color(0xFF3A3A48) : const Color(0xFFD8CEC0)),
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

// context opsional supaya pemanggil lama tetap jalan (default = warna gelap)
Color jarakColor(int rssi, [BuildContext? c]) {
  final light = c != null && !isDark(c);
  if (rssi >= -70) return light ? AppColors.lightGreen : AppColors.green;
  if (rssi >= -85) return light ? AppColors.lightAmber : AppColors.amber;
  return light ? AppColors.lightRed : AppColors.red;
}