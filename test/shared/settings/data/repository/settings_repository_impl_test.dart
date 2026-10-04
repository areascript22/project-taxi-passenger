import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:passenger_app/shared/settings/data/repository/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // SharedPreferences real contra su store en memoria: prueba de verdad la
  // serialización (`.name`) y el parseo, que es donde estaría el bug si la
  // preferencia no sobreviviera a un reinicio de la app.
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepositoryImpl();
  });

  group('language', () {
    test('sin nada guardado devuelve system (seguir al dispositivo)', () async {
      final result = await repository.getLanguage();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('esperaba un Right'),
        (language) => expect(language, AppLanguage.system),
      );
    });

    test('lo guardado sobrevive a una instancia nueva del repositorio', () async {
      await repository.setLanguage(AppLanguage.english);

      // Instancia nueva = lo que pasa al reabrir la app.
      final result = await SettingsRepositoryImpl().getLanguage();

      result.fold(
        (_) => fail('esperaba un Right'),
        (language) => expect(language, AppLanguage.english),
      );
    });

    test('se persiste como el nombre del enum, no como índice', () async {
      await repository.setLanguage(AppLanguage.spanish);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings_language'), 'spanish');
    });

    test('un valor desconocido cae a system en vez de reventar', () async {
      // Pasa si alguien renombra el enum o edita las prefs a mano.
      SharedPreferences.setMockInitialValues({
        'settings_language': 'klingon',
      });

      final result = await SettingsRepositoryImpl().getLanguage();

      result.fold(
        (_) => fail('esperaba un Right'),
        (language) => expect(language, AppLanguage.system),
      );
    });

    test('cambiar el idioma sobreescribe el anterior', () async {
      await repository.setLanguage(AppLanguage.english);
      await repository.setLanguage(AppLanguage.spanish);

      final result = await repository.getLanguage();

      result.fold(
        (_) => fail('esperaba un Right'),
        (language) => expect(language, AppLanguage.spanish),
      );
    });

    test('la preferencia de idioma no pisa las otras preferencias', () async {
      await repository.setVoiceEnabled(false);
      await repository.setLanguage(AppLanguage.english);

      final voice = await repository.isVoiceEnabled();

      voice.fold(
        (_) => fail('esperaba un Right'),
        (enabled) => expect(enabled, isFalse),
      );
    });
  });
}
