import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';
import 'last_location_service.dart';

class LastLocationServiceImpl implements LastLocationService {
  static const _latitudeKey = 'last_location_latitude';
  static const _longitudeKey = 'last_location_longitude';

  @override
  Future<Either<Failure, UserLocation?>> getLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble(_latitudeKey);
      final longitude = prefs.getDouble(_longitudeKey);
      if (latitude == null || longitude == null) {
        return const Right(null);
      }
      return Right(UserLocation(latitude: latitude, longitude: longitude));
    } catch (e) {
      debugPrint('LocationDebug | Error en getLastLocation: $e');
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveLastLocation({
    required UserLocation location,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latitudeKey, location.latitude);
      await prefs.setDouble(_longitudeKey, location.longitude);
      return const Right(unit);
    } catch (e) {
      debugPrint('LocationDebug | Error en saveLastLocation: $e');
      return Left(Failure(code: FailureCode.unexpected, detail: e.toString()));
    }
  }
}
