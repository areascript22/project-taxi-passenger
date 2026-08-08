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

  Future<void> dispose();

}