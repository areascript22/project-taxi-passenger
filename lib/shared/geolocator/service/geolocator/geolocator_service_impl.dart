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
      debugPrint("Checking permissions: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("Checking permissions again: $permission");
      }

      return Right(permission);
    } catch (e) {
      debugPrint("Error requesting location permissions: $e");
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>>   getCurrentPosition() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return Left(Failure(message: 'El servicio de GPS del dispositivo está desactivado.'));
      }

      final position = await Geolocator.getCurrentPosition();

      return Right(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final response = await Geolocator.openAppSettings();
      return Right(response);
    } catch (e) {
      debugPrint("Error opening app settings location: $e");
      return Left(Failure(message: e.toString()));
    }
  }
}