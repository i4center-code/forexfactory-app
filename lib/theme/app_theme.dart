import 'package:flutter/material.dart';

const kFont = 'IranYekan';

class AppInk {
  static const ink = Color(0xFF1B2333);
  static const muted = Color(0xFF6B7488);
  static const line = Color(0xFFE4E8F0);
}

/// کلید تم فعال کل اپ (از AppBar تا نوار پایین). فقط ظاهر را تغییر می‌دهد.
final ValueNotifier<String> appThemeKey = ValueNotifier<String>('forex');

/// تقویم فعال (فارکس/فلزات/انرژی/کریپتو)
final ValueNotifier<String> activeCalendar = ValueNotifier<String>('forex');

const kCalendarLabels = {
  'forex': 'تقویم فارکس',
  'metals': 'تقویم فلزات',
  'energy': 'تقویم انرژی',
  'crypto': 'تقویم کریپتو',
};
const kCalendarShort = {'forex': 'فارکس', 'metals': 'فلزات', 'energy': 'انرژی', 'crypto': 'کریپتو'};
const kCalendarIcons = {
  'forex': Icons.currency_exchange_rounded,
  'metals': Icons.diamond_outlined,
  'energy': Icons.bolt_rounded,
  'crypto': Icons.currency_bitcoin_rounded,
};

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.primary, required this.secondary, required this.accent});
  final Color primary;
  final Color secondary;
  final Color accent;

  /// پس‌زمینهٔ روشن با تینت بسیار ملایم رنگ تم
  Color get tint => Color.alphaBlend(primary.withValues(alpha: 0.05), const Color(0xFFF8F9FC));

  @override
  AppPalette copyWith({Color? primary, Color? secondary, Color? accent}) =>
      AppPalette(primary: primary ?? this.primary, secondary: secondary ?? this.secondary, accent: accent ?? this.accent);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

const kPalettes = <String, AppPalette>{
  'forex': AppPalette(primary: Color(0xFF1B346A), secondary: Color(0xFF2E4D8E), accent: Color(0xFF3FAE38)),
  'metals': AppPalette(primary: Color(0xFF5A2C26), secondary: Color(0xFF8A4A41), accent: Color(0xFFD4A574)),
  'energy': AppPalette(primary: Color(0xFF1A6231), secondary: Color(0xFF2A8F4A), accent: Color(0xFF2EA22B)),
  'crypto': AppPalette(primary: Color(0xFF463459), secondary: Color(0xFF6A4F91), accent: Color(0xFF8A6CB5)),
};

AppPalette paletteOf(String key) => kPalettes[key] ?? kPalettes['forex']!;

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? kPalettes['forex']!;
}

ThemeData buildAppTheme(AppPalette p) {
  final scheme = ColorScheme.fromSeed(seedColor: p.primary).copyWith(
    primary: p.primary,
    onPrimary: Colors.white,
    secondary: p.accent,
    surface: Colors.white,
    onSurface: AppInk.ink,
    surfaceTint: Colors.transparent,
    outline: AppInk.line,
    secondaryContainer: p.primary.withValues(alpha: 0.1),
    onSecondaryContainer: p.primary,
    primaryContainer: p.primary.withValues(alpha: 0.1),
    onPrimaryContainer: p.primary,
  );
  const base = TextStyle(fontFamily: kFont, fontWeight: FontWeight.w700, fontSize: 14);
  return ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.tint,
    canvasColor: Colors.white,
    extensions: <ThemeExtension<dynamic>>[p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: p.primary.withValues(alpha: 0.35),
      height: 68,
      indicatorColor: p.primary.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? p.primary : AppInk.muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: kFont,
          fontSize: 11.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
          color: s.contains(WidgetState.selected) ? p.primary : AppInk.muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.primary,
      contentTextStyle: const TextStyle(fontFamily: kFont, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: base,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: const Size(0, 46),
        side: BorderSide(color: p.primary.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: base,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primary, textStyle: base.copyWith(fontSize: 13)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.tint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(fontFamily: kFont, color: AppInk.muted, fontSize: 13),
      prefixIconColor: AppInk.muted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppInk.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppInk.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.primary, width: 1.6)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    dividerTheme: const DividerThemeData(color: AppInk.line, thickness: 1, space: 1),
  );
}
