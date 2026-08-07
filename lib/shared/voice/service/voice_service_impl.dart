import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_service.dart';

class VoiceServiceImpl implements VoiceService {
  final FlutterTts _flutterTts;
  bool _isConfigured = false;

  VoiceServiceImpl({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isConfigured = true;
  }

  @override
  Future<Either<Failure, Unit>> speak(String text) async {
    try {
      await _ensureConfigured();
      await _flutterTts.speak(text);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> stop() async {
    try {
      await _flutterTts.stop();
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
