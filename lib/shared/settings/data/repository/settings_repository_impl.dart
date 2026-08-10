import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repository/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _voiceKey = 'settings_voice_enabled';
  static const _vibrationKey = 'settings_vibration_enabled';
  static const _themeModeKey = 'settings_theme_mode';

  @override
  Future<Either<Failure, bool>> isVoiceEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Right(prefs.getBool(_voiceKey) ?? true);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isVibrationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Right(prefs.getBool(_vibrationKey) ?? true);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setVoiceEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_voiceKey, enabled);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setVibrationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, enabled);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      return Right(_themeModeFromString(stored));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  ThemeMode _themeModeFromString(String? value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
