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

  // Actualiza nombres/apellidos y (si corresponde) la foto de perfil de un
  // pasajero ya registrado. No toca email/fcmToken/status/createdAt. Devuelve
  // la entidad actualizada (con la photoUrl final) para refrescar la UI sin
  // tener que volver a leer el documento.
  Future<Either<Failure, PassengerEntity>> updatePassenger({
    required PassengerEntity passenger,
    File? profileImage,
  });

  // Guarda/actualiza el token FCM del pasajero en Firestore -- lo usa el
  // backend para enviarle push notifications.
  //
  // El idioma va en la MISMA escritura porque el backend necesita los dos
  // juntos: el token le dice a qué dispositivo mandar el push y el idioma en
  // qué lengua armarlo. `language` es un código ya resuelto ('es'/'en'),
  // nunca 'system': el server no puede resolver "seguir al dispositivo"
  // porque no conoce el idioma del teléfono.
  Future<Either<Failure, Unit>> updateFcmToken({
    required String passengerId,
    required String token,
    required String language,
  });

  // Actualiza solo el idioma, para cuando el pasajero lo cambia en Ajustes
  // teniendo el token ya registrado. Sin esto, el backend le seguiría
  // mandando push en el idioma viejo hasta el próximo arranque de la app.
  Future<Either<Failure, Unit>> updateLanguage({
    required String passengerId,
    required String language,
  });
}
