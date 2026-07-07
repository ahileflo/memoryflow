import 'package:flutter/material.dart';

/// MemoryFlow brand palette — the single source of truth for color.
///
/// These values mirror the approved prototype's CSS custom properties
/// (`MemoryFlow — Interactive Prototype.html`). Do not hardcode hex values
/// elsewhere in the app — always reference [BrandColors].
abstract final class BrandColors {
  static const Color indigo = Color(0xFF1B1533); // dark screen backgrounds
  static const Color indigo2 = Color(0xFF27204A); // raised dark surfaces
  static const Color violet = Color(0xFF6C5CE7); // brand accent
  static const Color violetDark = Color(0xFF4A3B8C);
  static const Color coral = Color(0xFFFF7A59); // PRIMARY CALL-TO-ACTION
  static const Color amber = Color(0xFFFFB454);
  static const Color mint = Color(0xFF2EC4B6); // success / "active"
  static const Color ink = Color(0xFF252140); // primary text
  static const Color muted = Color(0xFF7A7690); // secondary text
  static const Color panel = Color(0xFFF4F2FB); // light fill
  static const Color line = Color(0xFFE4E0F2); // hairline borders
  static const Color bg = Color(0xFF0E0B1C); // app backdrop
}

/// Shared rounded-corner radii used by the "photo tile" / soft-card motif.
abstract final class BrandRadius {
  static const double card = 20;
  static const double tile = 14;
  static const double button = 16;
  static const double pill = 999;
}

/// Soft drop shadow used on cards and the coral primary button.
List<BoxShadow> softShadow({Color? color, double opacity = 0.12}) => [
      BoxShadow(
        color: (color ?? BrandColors.indigo).withValues(alpha: opacity),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];

/// Builds the global [ThemeData]. Warm, premium, effortless — light surfaces
/// with the violet/coral accent system.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.violet,
    onPrimary: Colors.white,
    secondary: BrandColors.coral,
    onSecondary: Colors.white,
    tertiary: BrandColors.amber,
    onTertiary: BrandColors.ink,
    surface: Colors.white,
    onSurface: BrandColors.ink,
    surfaceContainerHighest: BrandColors.panel,
    error: Color(0xFFE5484D),
    onError: Colors.white,
    outline: BrandColors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Roboto',
  );

  // Type scale modeled on the prototype (large, tight, bold headings).
  final textTheme = base.textTheme.copyWith(
    displaySmall: const TextStyle(
        fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: BrandColors.ink),
    headlineMedium: const TextStyle(
        fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: BrandColors.ink),
    titleLarge: const TextStyle(
        fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: BrandColors.ink),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BrandColors.ink),
    bodyLarge: const TextStyle(fontSize: 15.5, height: 1.5, color: BrandColors.ink),
    bodyMedium: const TextStyle(fontSize: 14.5, height: 1.5, color: BrandColors.muted),
    labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  return base.copyWith(
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    dividerTheme: const DividerThemeData(color: BrandColors.line, thickness: 1, space: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: BrandColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
