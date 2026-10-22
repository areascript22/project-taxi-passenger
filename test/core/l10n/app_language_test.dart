import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage.locale', () {
    test('system devuelve null para que Flutter resuelva con el dispositivo', () {
      expect(AppLanguage.system.locale, isNull);
    });

    test('las opciones explícitas devuelven su locale', () {
      expect(AppLanguage.spanish.locale, const Locale('es'));
      expect(AppLanguage.english.locale, const Locale('en'));
    });
  });

  group('resolveAppLocale', () {
    Locale resolve(AppLanguage preference, List<Locale>? devices) =>
        resolveAppLocale(preference: preference, deviceLocales: devices);

    test('una elección explícita gana sobre el idioma del dispositivo', () {
      expect(
        resolve(AppLanguage.english, [const Locale('es', 'EC')]),
        const Locale('en'),
      );
      expect(
        resolve(AppLanguage.spanish, [const Locale('en', 'US')]),
        const Locale('es'),
      );
    });

    test('con "Sistema" usa el idioma del dispositivo si está soportado', () {
      expect(
        resolve(AppLanguage.system, [const Locale('en', 'GB')]),
        const Locale('en'),
      );
      expect(
        resolve(AppLanguage.system, [const Locale('es', 'MX')]),
        const Locale('es'),
      );
    });

    // Este es el caso que Flutter NO resuelve como queremos: su fallback
    // implícito es el primer elemento de supportedLocales, que el generador
    // ordena alfabéticamente ([en, es]). Sin resolveAppLocale, un teléfono en
    // portugués abriría la app en inglés.
    test('cae a español cuando el idioma del dispositivo no está soportado', () {
      expect(
        resolve(AppLanguage.system, [const Locale('pt', 'BR')]),
        fallbackLocale,
      );
      expect(fallbackLocale, const Locale('es'));
    });

    test('respeta el ORDEN de preferencia del dispositivo', () {
      // Teléfono con francés primero e inglés segundo: corresponde inglés,
      // no el fallback a español.
      expect(
        resolve(AppLanguage.system, [const Locale('fr'), const Locale('en')]),
        const Locale('en'),
      );
    });

    test('cae a español sin lista de locales (null o vacía)', () {
      expect(resolve(AppLanguage.system, null), fallbackLocale);
      expect(resolve(AppLanguage.system, const []), fallbackLocale);
    });

    test('ignora el país: solo matchea por idioma', () {
      expect(
        resolve(AppLanguage.system, [const Locale('es', 'AR')]),
        const Locale('es'),
      );
    });
  });

  group('resolveSystemAppLocale', () {
    test('una elección explícita no depende del idioma del sistema', () {
      expect(
        resolveSystemAppLocale(preference: AppLanguage.english),
        const Locale('en'),
      );
      expect(
        resolveSystemAppLocale(preference: AppLanguage.spanish),
        const Locale('es'),
      );
    });

    // Lo que se guarda en Firestore para los push sale de acá, y el backend
    // solo entiende idiomas concretos: 'system' nunca puede llegar a salir.
    test('siempre devuelve un idioma soportado, nunca "system"', () {
      for (final preference in AppLanguage.values) {
        expect(
          resolveSystemAppLocale(preference: preference).languageCode,
          isIn(const ['es', 'en']),
        );
      }
    });
  });
}
