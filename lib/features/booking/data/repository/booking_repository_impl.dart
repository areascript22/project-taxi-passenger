import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/request_entity.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseDatabase database;
  final Dio _dio = DioClient.instance;

  BookingRepositoryImpl({required this.database});

  @override
  Future<Either<Failure, String>> requestTaxi({
    required RequestEntity request,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return Left(
          Failure(message: 'Usuario no autenticado. Inicie sesión nuevamente.'),
        );
      }

      final String userId = currentUser.uid;

      // 1. Reference directly to /taxi_requests/{userId}
      final DatabaseReference requestRef = database.ref()
          .child('taxi_requests')
          .child(userId); // 👈 This is the key: userId

      // 2. Generate a unique rideId (for tracking purposes)
      final String rideId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Structure the data payload
      final Map<String, dynamic> rideData = {
        'rideId': rideId,
        'userId': userId, // Keep this for queries
        'passenger': {
          'name': request.userName,
          'profileImage': request.userProfileImage,
        },
        'pickupLocation': {
          'latitude': request.pickupLat,
          'longitude': request.pickupLng,
          'address': request.pickupAddress,
        },
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp, // For tracking updates
      };

      // 4. Write the data - this will CREATE or UPDATE
      await requestRef.set(rideData); // 👈 No .push() here!

      // 5. Return the rideId
      return Right(rideId);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo solicitar el taxi. Intente de nuevo.'),
      );
    }
  }

  // Ya no borra directo el nodo de Realtime Database: pasa por el backend
  // (RideService.cancelRide), la misma transacción que ya usa RideTracking
  // para cancelar viajes en curso. Así, si el pasajero cancela justo cuando
  // un conductor acepta, Firebase decide de forma atómica cuál de las dos
  // operaciones gana -- nunca se pierde la solicitud a mitad de camino.
  @override
  Future<Either<Failure, Unit>> cancelTaxiRequest() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return Left(
          Failure(message: 'Usuario no autenticado. Inicie sesión nuevamente.'),
        );
      }

      await _dio.post('/api/rides/${currentUser.uid}/cancel');
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('BookingDebug | Error en cancelTaxiRequest: $e');
      if (e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        return Left(
          Failure(message: 'La solicitud ya no está disponible para cancelar.'),
        );
      }
      return Left(
        Failure(message: 'No se pudo cancelar la solicitud. Intente de nuevo.'),
      );
    } catch (e) {
      debugPrint('BookingDebug | Error inesperado en cancelTaxiRequest: $e');
      return Left(
        Failure(message: 'No se pudo cancelar la solicitud. Intente de nuevo.'),
      );
    }
  }

}
