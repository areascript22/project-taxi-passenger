import 'package:dartz/dartz.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import '../../../../core/error/errors.dart';

abstract class BookingRepository {
  Future<Either<Failure, String>> requestTaxi({required RequestEntity request});
  Future<Either<Failure, Unit>> cancelTaxiRequest();
}
