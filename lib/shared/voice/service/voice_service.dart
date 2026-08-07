import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

abstract class VoiceService {
  Future<Either<Failure, Unit>> speak(String text);
  Future<Either<Failure, Unit>> stop();
}
