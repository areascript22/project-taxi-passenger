import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';

abstract interface class GeocodingRepository{
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double lat,
    required double lng,
  });
}