import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/booking/domain/entity/place_entity.dart';

abstract interface class LocationSearchRepository {
  Future<Either<Failure, List<PlaceEntity>>> getAutocompletePlaces({
    required String query,
  });
}
