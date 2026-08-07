import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:vibration/vibration.dart';
import 'vibration_service.dart';

class VibrationServiceImpl implements VibrationService {
  @override
  Future<Either<Failure, Unit>> vibrate({int durationMs = 400}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(duration: durationMs);
      }
      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
