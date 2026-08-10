import 'package:flutter/material.dart';
import 'app_colors.dart';

// Paleta central de la app -- idéntica a driver_app (misma marca TaxiGo):
// Dark Theme navy 1A1A2E/16213E/0F3460 + acento coral E94560, Light Theme
// derivado manteniendo la misma relación tonal.
class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFFE94560);
  static const _onPrimary = Colors.white;
  static const _secondary = Color(0xFF16C79A);
  static const _error = Color(0xFFE74C3C);
  static const _onError = Colors.white;

  static final ColorScheme _darkScheme = const ColorScheme.dark(
    primary: _primary,
    onPrimary: _onPrimary,
    secondary: _secondary,
    onSecondary: Colors.white,
    error: _error,
    onError: _onError,
    // Mismo tono que antes se usaba a mano para diálogos/tarjetas
    // (Color(0xFF16213E)).
    surface: Color(0xFF16213E),
    onSurface: Colors.white,
  );

  // onSurface reutiliza el tono más oscuro del gradiente dark (1A1A2E) como
  // color de texto -- así el Light Theme queda tonalmente "anclado" al
  // Dark Theme en vez de ser un blanco/negro genérico sin relación.
  static final ColorScheme _lightScheme = const ColorScheme.light(
    primary: _primary,
    onPrimary: _onPrimary,
    secondary: _secondary,
    onSecondary: Colors.white,
    error: _error,
    onError: _onError,
    surface: Colors.white,
    onSurface: Color(0xFF1A1A2E),
  );

  static ThemeData get dark => _build(
    colorScheme: _darkScheme,
    appColors: AppColors.dark,
    scaffoldBackground: const Color(0xFF1A1A2E),
  );

  static ThemeData get light => _build(
    colorScheme: _lightScheme,
    appColors: AppColors.light,
    scaffoldBackground: const Color(0xFFF8F8FC),
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppColors appColors,
    required Color scaffoldBackground,
  }) {
    final onSurface = colorScheme.onSurface;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: [appColors],
      dividerColor: onSurface.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? colorScheme.primary
                  : null,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.error,
        contentTextStyle: TextStyle(color: colorScheme.onError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
