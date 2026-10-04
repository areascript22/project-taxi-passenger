import 'package:dartz/dartz.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:passenger_app/shared/settings/domain/repository/settings_repository.dart';
import 'voice_service.dart';

class VoiceServiceImpl implements VoiceService {
  final FlutterTts _flutterTts;
  final SettingsRepository settingsRepository;

  // Idioma con el que quedo configurado el motor de TTS. Se guarda para no
  // reconfigurarlo en cada frase, pero SI cuando el usuario cambia el idioma
  // en Ajustes: sin esto, elegir ingles dejaria el texto ingles leido con voz
  // española (suena mal y a veces es ininteligible).
  String? _configuredTag;
  bool _tunedOnce = false;

  VoiceServiceImpl({required this.settingsRepository, FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  // El idioma de la voz sale de la misma preferencia que el de la UI, no del
  // locale del sistema: si el usuario puso la app en ingles, la voz tambien.
  Future<String> _resolveLanguageTag() async {
    final result = await settingsRepository.getLanguage();
    final preference = result.fold((_) => AppLanguage.system, (value) => value);
    final locale = resolveSystemAppLocale(preference: preference);
    return switch (locale.languageCode) {
      'en' => 'en-US',
      _ => 'es-ES',
    };
  }

  Future<void> _ensureConfigured() async {
    final tag = await _resolveLanguageTag();
    if (_configuredTag == tag) return;

    await _flutterTts.setLanguage(tag);
    if (!_tunedOnce) {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _tunedOnce = true;
    }
    _configuredTag = tag;
  }

  @override
  Future<Either<Failure, Unit>> speak(String text) async {
    try {
      await _ensureConfigured();
      await _flutterTts.speak(text);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> stop() async {
    try {
      await _flutterTts.stop();
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }
}
