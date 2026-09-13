import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/request_entity.dart';

class BookingRepositoryImpl implements BookingRepository {
  final Dio _dio = DioClient.instance;

  // Ya no escribe directo a Realtime Database: pasa por el backend
  // (RideService.requestRide), que agenda ahí mismo la auto-cancelación de
  // la solicitud si nadie la acepta a tiempo (ver PENDING_REQUEST_EXPIRY_SECONDS
  // server-side), y deriva nombre/foto del pasajero del token verificado en
  // vez de confiar en lo que mande el cliente.
  @override
  Future<Either<Failure, Unit>> requestTaxi({
    required RequestEntity request,
  }) async {
    try {
      await _dio.post(
        '/api/rides/request',
        data: {
          'latitude': request.pickupLat,
          'longitude': request.pickupLng,
          'address': request.pickupAddress,
        },
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('BookingDebug | Error en requestTaxi: $e');
      return Left(
        Failure(message: 'No se pudo solicitar el taxi. Intente de nuevo.'),
      );
    } catch (e) {
      debugPrint('BookingDebug | Error inesperado en requestTaxi: $e');
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
