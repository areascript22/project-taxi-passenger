import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

/// Idioma que el usuario eligió en Ajustes.
///
/// Tres valores, igual que el selector de tema (Oscuro/Claro/Sistema):
/// [system] es el default y significa "seguir al dispositivo", así que si el
/// usuario cambia el idioma del teléfono la app lo acompaña. Guardar
/// directamente 'es'/'en' al primer arranque dejaría al usuario clavado a ese
/// valor, sin forma de volver a seguir al sistema.
enum AppLanguage {
  system,
  spanish,
  english;

  /// Locale a pasarle al `MaterialApp`. `null` = que Flutter resuelva con el
  /// idioma del dispositivo (ver [resolveAppLocale]).
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.spanish => const Locale('es'),
    AppLanguage.english => const Locale('en'),
  };
}

/// Idioma al que se cae cuando el del dispositivo no es ninguno de los
/// soportados (un teléfono en francés, por ejemplo).
///
/// Es explícito a propósito: el fallback implícito de Flutter es el PRIMER
/// elemento de `supportedLocales`, y el generador los ordena alfabéticamente,
/// o sea `[en, es]`. Sin esto, un teléfono en portugués abriría la app en
/// inglés, no en español.
const fallbackLocale = Locale('es');

/// Locale efectivo de la app: el elegido por el usuario; si eligió "Sistema",
/// el primero de los idiomas del dispositivo que esté soportado; y si ninguno
/// lo está, [fallbackLocale].
///
/// Recibe la LISTA de locales del dispositivo (no uno solo) porque Android e
/// iOS exponen las preferencias de idioma en orden: alguien puede tener
/// francés primero e inglés segundo, y ahí corresponde inglés, no español.
Locale resolveAppLocale({
  required AppLanguage preference,
  required List<Locale>? deviceLocales,
}) {
  final chosen = preference.locale;
  if (chosen != null) return chosen;

  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == device.languageCode) return supported;
    }
  }
  return fallbackLocale;
}

/// [resolveAppLocale] para el código que corre **sin `BuildContext`** y por lo
/// tanto no tiene a mano la lista de idiomas del dispositivo: el TTS y la
/// escritura del idioma en Firestore.
///
/// Es un wrapper y no una implementación aparte a propósito: la resolución
/// tiene que ser la misma que la del `MaterialApp`, o la app hablaría en un
/// idioma y escribiría en otro.
Locale resolveSystemAppLocale({required AppLanguage preference}) {
  // Platform.localeName viene como 'es_EC' / 'en-US': solo interesa el idioma.
  final systemLocale = Locale(Platform.localeName.split(RegExp('[_-]')).first);

  return resolveAppLocale(
    preference: preference,
    deviceLocales: [systemLocale],
  );
}
