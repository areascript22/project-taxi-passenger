import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

abstract class VibrationService {
  Future<Either<Failure, Unit>> vibrate({int durationMs = 400});
}
