import '../entity/ride_entity.dart';

abstract class RideTrackingRepository {

  Stream<RideEntity> watchRideTrack({
    required String passengerId,
  });

  Future<void> dispose();

}