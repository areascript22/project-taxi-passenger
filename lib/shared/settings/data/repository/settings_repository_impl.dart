import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/core/l10n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repository/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _voiceKey = 'settings_voice_enabled';
  static const _vibrationKey = 'settings_vibration_enabled';
  static const _themeModeKey = 'settings_theme_mode';
  static const _languageKey = 'settings_language';

  @override
  Future<Either<Failure, bool>> isVoiceEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Right(prefs.getBool(_voiceKey) ?? true);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isVibrationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Right(prefs.getBool(_vibrationKey) ?? true);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setVoiceEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_voiceKey, enabled);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setVibrationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, enabled);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      return Right(_themeModeFromString(stored));
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppLanguage>> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_languageKey);
      return Right(_languageFromString(stored));
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.name);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  // Sin valor guardado (o con uno que ya no existe, ej. tras renombrar el
  // enum) se asume 'system': el default es seguir al dispositivo.
  AppLanguage _languageFromString(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.system,
    );
  }

  ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
