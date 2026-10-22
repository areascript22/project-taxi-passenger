import 'package:flutter/material.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:toastification/toastification.dart';

/// Toasts de la app. Dos variantes, que solo se diferencian en color e ícono:
///
/// - [AppToast.success] -> verde semántico (`appColors.success`). Se usa tanto
///   para confirmaciones ("Perfil actualizado") como para avisos
///   informativos.
/// - [AppToast.error] -> rojo del tema (`colorScheme.error`). Para cualquier
///   resultado negativo: fallos de red, validaciones, acciones que no se
///   pudieron completar.
///
/// Reemplaza los `ScaffoldMessenger.of(context).showSnackBar(...)` que había
/// repartidos por las screens, que tenían dos problemas:
///
///  1. El `snackBarTheme` de AppTheme pinta TODO SnackBar con
///     `colorScheme.error`, así que los mensajes de éxito también salían
///     rojos.
///  2. Un SnackBar vive en el `Scaffold`, y acá el `ScaffoldWithNavBar` apila
///     el bottom nav bar por encima del contenido: el SnackBar del `Scaffold`
///     interno de cada branch queda tapado por esa barra. Estos toasts se
///     montan en el overlay raíz (`rootOverlay: true`), así que se ven por
///     encima de todo, incluidos diálogos.
///
/// Nota sobre la convención del CLAUDE.md (sección 2): los diálogos son
/// `StatelessWidget` con un `show` estático porque nosotros construimos el
/// widget. Acá el widget lo construye `toastification`, así que no hay nada
/// nuestro que buildear y esto es una clase de utilidades con métodos
/// estáticos. Se mantiene lo importante de la regla: ninguna screen llama a
/// `toastification.show(...)` directo, siempre pasa por `AppToast`.
class AppToast {
  AppToast._();

  // Los errores quedan un segundo más: suelen pedir que el usuario lea y
  // decida si reintenta, mientras una confirmación solo se acusa recibo.
  static const _successDuration = Duration(seconds: 3);
  static const _errorDuration = Duration(seconds: 4);

  static void success(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _show(
      context,
      message: message,
      title: title,
      color: context.appColors.success,
      icon: Icons.check_circle_rounded,
      type: ToastificationType.success,
      duration: _successDuration,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    _show(
      context,
      message: message,
      title: title,
      color: Theme.of(context).colorScheme.error,
      icon: Icons.error_rounded,
      type: ToastificationType.error,
      duration: _errorDuration,
    );
  }

  // Las dos variantes comparten layout, tipografía, animación y
  // comportamiento: lo único que cambia es `color`, `icon` y la duración.
  static void _show(
    BuildContext context, {
    required String message,
    required String? title,
    required Color color,
    required IconData icon,
    required ToastificationType type,
    required Duration duration,
  }) {
    // `fillColored` pinta el fondo con `primaryColor` y deja el texto en
    // `foregroundColor` -- mismo criterio de blanco sobre color de marca que
    // ya usaba el snackBarTheme (onError sobre error).
    const foreground = Colors.white;

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: duration,
      primaryColor: color,
      foregroundColor: foreground,
      icon: Icon(icon, color: foreground),
      title:
          title == null
              ? Text(
                message,
                style: const TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
              : Text(
                title,
                style: const TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      description:
          title == null
              ? null
              : Text(
                message,
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
      borderRadius: BorderRadius.circular(16),
      showProgressBar: false,
      // Sin botón de cerrar: se auto-cierra, se puede tocar para descartar y
      // arrastrar para sacarlo. Una "X" en un toast de 3 segundos solo mete
      // ruido visual.
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      closeOnClick: true,
      dragToClose: true,
    );
  }
}
