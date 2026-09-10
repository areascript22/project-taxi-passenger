import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';
import 'geolocator_service.dart';

class GeolocatorServiceServiceImpl implements GeolocatorService {
  @override
  Future<Either<Failure, LocationPermission>> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint("LocationDebug | Checking permissions: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("LocationDebug | Checking permissions again: $permission");
      }

      return Right(permission);
    } catch (e) {
      debugPrint("LocationDebug | Error requesting location permissions: $e");
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> getCurrentPosition() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint("LocationDebug | isLocationServiceEnabled -> $isServiceEnabled");
      if (!isServiceEnabled) {
        return Left(Failure(message: 'El servicio de GPS del dispositivo está desactivado.'));
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on TimeoutException {
        // Sin fix de GPS a tiempo (interiores, señal débil, etc.) -- mejor
        // usar la última posición conocida que dejar al usuario colgado
        // indefinidamente en "Obteniendo tu ubicación...".
        debugPrint(
          "LocationDebug | getCurrentPosition() sin respuesta en 10s, probando última posición conocida",
        );
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return Left(
          Failure(message: 'No se pudo obtener tu ubicación. Intenta de nuevo.'),
        );
      }

      debugPrint(
        "LocationDebug | Posición obtenida: (${position.latitude}, ${position.longitude})",
      );
      return Right(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      debugPrint("LocationDebug | Error en getCurrentPosition: $e");
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final response = await Geolocator.openAppSettings();
      return Right(response);
    } catch (e) {
      debugPrint("LocationDebug | Error opening app settings location: $e");
      return Left(Failure(message: e.toString()));
    }
  }
}