import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';

abstract class GeolocatorService {
  Future<Either<Failure, LocationPermission>> checkAndRequestPermission();
  Future<Either<Failure, UserLocation>> getCurrentPosition();
  Future<Either<Failure, bool>> openAppSettings();
}