import 'package:flutter/material.dart';

/// App-wide themes: Material 3 from the brand orange, light and dark.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFFEF6C00);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [dark ? AppColors.dark : AppColors.light],
      // Cards sit on the gradient background: a tonal surface instead of the
      // default shadow, which is nearly invisible on dark backgrounds.
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 1,
        color: dark ? scheme.surfaceContainerHigh : null,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.fixed),
    );
  }
}

/// Meaning-carrying colors that the Material scheme does not have, tuned per
/// brightness (a light-theme green or amber is too dark to read on dark surfaces).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.favorite});

  /// "Done", "trend up".
  final Color success;

  /// Favorites star and personal records.
  final Color favorite;

  static const light = AppColors(success: Color(0xFF2E7D32), favorite: Color(0xFFE69500));
  static const dark = AppColors(success: Color(0xFF81C784), favorite: Color(0xFFFFCA28));

  @override
  AppColors copyWith({Color? success, Color? favorite}) =>
      AppColors(success: success ?? this.success, favorite: favorite ?? this.favorite);

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(success: Color.lerp(success, other.success, t)!, favorite: Color.lerp(favorite, other.favorite, t)!);
}

extension AppColorsX on BuildContext {
  /// Falls back to the light set when a test pumps a bare Theme without the extension.
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
