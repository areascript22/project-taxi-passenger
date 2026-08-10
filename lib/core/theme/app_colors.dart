import 'package:flutter/material.dart';

// Colores "de marca" que no tienen un rol equivalente en el ColorScheme
// estándar de Material 3 (gradiente de fondo, éxito, advertencia). Todo lo
// demás (acento, superficie de tarjetas, texto, error) vive en el
// ColorScheme de cada tema -- ver app_theme.dart.
//
// Paleta idéntica a driver_app (misma marca TaxiGo, mismo Dark/Light) --
// ver [[project-driver-app-theming]] en la memoria del proyecto si hace
// falta cambiarla, para mantener ambas apps sincronizadas.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final List<Color> backgroundGradient;
  final Color success;
  final Color warning;

  const AppColors({
    required this.backgroundGradient,
    required this.success,
    required this.warning,
  });

  static const dark = AppColors(
    backgroundGradient: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
    success: Color(0xFF16C79A),
    warning: Color(0xFFF5A623),
  );

  // Misma dirección de tono (frío, azul/índigo) que el gradiente oscuro,
  // pero llevado a valores altos de luminosidad -- mantiene la relación
  // visual con el Dark Theme sin ser un simple blanco plano.
  static const light = AppColors(
    backgroundGradient: [
      Color(0xFFF8F8FC),
      Color(0xFFEFF1FA),
      Color(0xFFE4E9F7),
    ],
    success: Color(0xFF16C79A),
    warning: Color(0xFFF5A623),
  );

  @override
  AppColors copyWith({
    List<Color>? backgroundGradient,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      backgroundGradient: [
        for (var i = 0; i < backgroundGradient.length; i++)
          Color.lerp(backgroundGradient[i], other.backgroundGradient[i], t)!,
      ],
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
