import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

abstract class SettingsRepository {
  Future<Either<Failure, bool>> isVoiceEnabled();
  Future<Either<Failure, bool>> isVibrationEnabled();
  Future<Either<Failure, Unit>> setVoiceEnabled(bool enabled);
  Future<Either<Failure, Unit>> setVibrationEnabled(bool enabled);
}
