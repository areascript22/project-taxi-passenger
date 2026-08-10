import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/passenger_entity.dart';

abstract class PassengerProfileRepository {
  // Devuelve null (dentro de Right) si el pasajero autenticado todavía no
  // tiene datos guardados en Firestore -- señal de que es un usuario nuevo
  // y debe pasar por el flujo de registro.
  Future<Either<Failure, PassengerEntity?>> getPassenger({
    required String passengerId,
  });

  // Sube (si corresponde) la foto de perfil a Storage y guarda el documento
  // del pasajero.
  Future<Either<Failure, Unit>> registerPassenger({
    required PassengerEntity passenger,
    File? profileImage,
  });
}
