import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/ride_entity.dart';
import '../../domain/repository/ride_tracking_repository.dart';

class RideTrackingRepositoryImpl implements RideTrackingRepository {
  final FirebaseDatabase database;
  final Dio _dio = DioClient.instance;

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

  // Ya no escribe directo a Realtime Database: pasa por el backend
  // (RideService.cancelRide) para que verifique con el token de Firebase
  // que quien cancela es realmente el pasajero dueño del viaje, y para que
  // el servidor pueda avisarle al conductor por push (el cliente no tiene
  // acceso al Admin SDK de FCM).
  @override
  Future<Either<Failure, Unit>> cancelRide({required String passengerId}) async {
    try {
      await _dio.post('/api/rides/$passengerId/cancel');
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('RideTrackingDebug | Error en cancelRide: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(message: 'No tienes permiso para cancelar este viaje.'),
        );
      }
      if (e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        return Left(
          Failure(message: 'El viaje ya no está disponible para cancelar.'),
        );
      }
      return Left(
        Failure(message: 'No se pudo cancelar el viaje. Intenta de nuevo.'),
      );
    } catch (e) {
      debugPrint('RideTrackingDebug | Error inesperado en cancelRide: $e');
      return Left(
        Failure(message: 'No se pudo cancelar el viaje. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> confirmOnTheWay({
    required String passengerId,
  }) async {
    try {
      await database.ref('taxi_requests/$passengerId').update({
        'status': 'tripStarted',
        'updatedAt': ServerValue.timestamp,
      });
      return const Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo confirmar. Intenta de nuevo.'),
      );
    }
  }

  // Ya no lee directo taxi_requests/{passengerId}: pasa por el backend
  // (RideService.findActiveRideForPassenger), que identifica al pasajero
  // por el token verificado en vez de confiar en un id que el cliente
  // podría pasar. El backend devuelve el mismo nodo crudo de Realtime
  // Database, así que RideEntity.fromJson lo parsea igual que cuando venía
  // del listener en vivo (watchRideTrack).
  @override
  Future<Either<Failure, RideEntity?>> getActiveRide() async {
    try {
      final response = await _dio.get('/api/rides/passenger/active');
      if (response.statusCode == 204 || response.data == null) {
        return const Right(null);
      }

      final ride = RideEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      return Right(ride);
    } on DioException catch (e) {
      debugPrint('RideTrackingDebug | Error en getActiveRide: $e');
      return Left(
        Failure(message: 'No se pudo verificar si tienes un viaje en curso.'),
      );
    } catch (e) {
      debugPrint('RideTrackingDebug | Error inesperado en getActiveRide: $e');
      return Left(
        Failure(message: 'No se pudo verificar si tienes un viaje en curso.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> recordInitialDriverDistance({
    required String passengerId,
    required double distanceMeters,
  }) async {
    try {
      final ref = database.ref('taxi_requests/$passengerId/driver');

      await ref.runTransaction((mutableData) {
        if (mutableData == null) return Transaction.abort();

        final data = Map<dynamic, dynamic>.from(mutableData as Map);
        // Ya se registró antes (ej. la app se reabrió a mitad del viaje) --
        // no lo pisamos, es una referencia fija de todo el viaje.
        if (data['initialDistance'] != null) return Transaction.abort();

        data['initialDistance'] = distanceMeters;
        return Transaction.success(data);
      });

      return const Right(unit);
    } catch (e) {
      debugPrint('RideTrackingDebug | Error en recordInitialDriverDistance: $e');
      return Left(
        Failure(message: 'No se pudo registrar la distancia inicial del conductor.'),
      );
    }
  }

  @override
  Future<void> dispose() async {}
}
