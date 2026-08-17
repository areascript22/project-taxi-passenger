import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/ride_entity.dart';

abstract class RideTrackingRepository {

  Stream<RideEntity> watchRideTrack({
    required String passengerId,
  });

  // Cancela un viaje que ya está en progreso (con conductor asignado).
  // No debe usarse para una solicitud aún pendiente: eso lo maneja
  // BookingRepository.cancelTaxiRequest.
  Future<Either<Failure, Unit>> cancelRide({
    required String passengerId,
  });

  // El pasajero confirma que va camino al vehículo tras ver que el
  // conductor llegó al punto de recogida.
  Future<Either<Failure, Unit>> confirmOnTheWay({
    required String passengerId,
  });

  // Guarda, solo si todavía no existe, la distancia (metros) del conductor
  // al punto de recogida en el momento en que se detecta por primera vez --
  // referencia fija para normalizar DriverDistanceIndicator. Si el campo ya
  // existe (ej. la app se reabrió a mitad del viaje), no hace nada.
  Future<Either<Failure, Unit>> recordInitialDriverDistance({
    required String passengerId,
    required double distanceMeters,
  });

  // Lectura puntual (no stream): ¿el pasajero tiene un viaje en curso
  // (conductor asignado en adelante)? Null == no hay viaje activo. Se usa
  // al iniciar la app para decidir si hay que resumir RideTrackingScreen en
  // vez de ir a BookingScreen.
  Future<Either<Failure, RideEntity?>> getActiveRide({
    required String passengerId,
  });

  Future<void> dispose();

}