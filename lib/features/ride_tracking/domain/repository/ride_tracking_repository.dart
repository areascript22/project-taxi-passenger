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

  // Lectura puntual (no stream): ¿el pasajero tiene un viaje en curso
  // (conductor asignado en adelante)? Null == no hay viaje activo. Se usa
  // al iniciar la app para decidir si hay que resumir RideTrackingScreen en
  // vez de ir a BookingScreen.
  Future<Either<Failure, RideEntity?>> getActiveRide({
    required String passengerId,
  });

  Future<void> dispose();

}