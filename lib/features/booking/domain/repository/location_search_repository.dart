import 'package:dartz/dartz.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import '../../../../core/error/errors.dart';

abstract class LocationSearchRepository {
  Future<Either<Failure, List<PlaceEntity>>> getAutocompletePlaces({
    required String query,
  });


  Future<Either<Failure, PlaceEntity>> getPlaceDetails({
    required String placeId,
  });
}
