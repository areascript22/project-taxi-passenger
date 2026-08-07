import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

// Orquesta voz + vibración respetando las preferencias del usuario
// (Settings). Es el único punto de entrada que el resto de la app debe usar
// para notificaciones habladas/hápticas -- así ningún feature necesita
// saber cómo se guardan las preferencias ni cómo hablar/vibrar por su cuenta.
abstract class FeedbackService {
  Future<Either<Failure, Unit>> announce(
    String message, {
    bool withVibration = false,
  });
}
