import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/ride_entity.dart';
import '../../domain/repository/ride_tracking_repository.dart';

class RideTrackingRepositoryImpl implements RideTrackingRepository {
  final FirebaseDatabase database;

  RideTrackingRepositoryImpl({required this.database});

  @override
  Stream<RideEntity> watchRideTrack({required String passengerId}) {
    debugPrint("WATCHING RIDE START...");

    return database.ref("taxi_requests/$passengerId").onValue.map((event) {
      final rawData = event.snapshot.value;

      final map =
          rawData == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(rawData as Map);

      debugPrint("WATCH RIDE: $map");

      return RideEntity.fromJson(map);
    });
  }

  @override
  Future<Either<Failure, Unit>> cancelRide({required String passengerId}) async {
    try {
      await database.ref('taxi_requests/$passengerId').update({
        'status': 'cancelled',
        'cancelledBy': 'passenger',
        'updatedAt': ServerValue.timestamp,
      });
      return const Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo cancelar el viaje. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
