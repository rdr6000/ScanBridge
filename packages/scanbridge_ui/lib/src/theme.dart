import 'package:flutter/material.dart';

/// 8-point spacing scale.
abstract final class Sb {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const radius = 10.0;
}

enum Tone { success, warning, error, info, neutral }

/// Semantic status colors that stay readable in light and dark themes.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.warning, required this.error, required this.info, required this.neutral});

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color neutral;

  Color of(Tone t) => switch (t) {
    Tone.success => success,
    Tone.warning => warning,
    Tone.error => error,
    Tone.info => info,
    Tone.neutral => neutral,
  };

  static const light = StatusColors(
    success: Color(0xFF1B7F4B),
    warning: Color(0xFF9A6200),
    error: Color(0xFFB3261E),
    info: Color(0xFF1F5FAF),
    neutral: Color(0xFF5F6368),
  );

  static const dark = StatusColors(
    success: Color(0xFF6DD39A),
    warning: Color(0xFFF2B84B),
    error: Color(0xFFF2877F),
    info: Color(0xFF8AB4F8),
    neutral: Color(0xFFB0B4BA),
  );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(StatusColors? other, double t) => t < .5 || other == null ? this : other;
}

abstract final class SbTheme {
  static const _seed = Color(0xFF2B6CB0);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sb.radius));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      extensions: [b == Brightness.light ? StatusColors.light : StatusColors.dark],
      cardTheme: CardThemeData(
        elevation: 0,
        shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(64, 44), shape: shape)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44), shape: shape)),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: Sb.m)),
    );
  }
}

extension ThemeX on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
