import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

class DriverEntity {
  final String name;
  final String photo;

  DriverEntity({required this.name, required this.photo});

  factory DriverEntity.fromJson(Map<String, dynamic> json) {
    return DriverEntity(
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
    );
  }
}

class RideEntity {
  final DriverEntity driver;
  final RideTrackingStatus rideStatus;

  RideEntity({
    required this.driver,
    this.rideStatus = RideTrackingStatus.initial,
  });

  factory RideEntity.fromJson(Map<String, dynamic> json) {
    return RideEntity(
      driver: DriverEntity.fromJson(json),
      rideStatus: _statusMapper(json['status'] as String?),
    );
  }

  static RideTrackingStatus _statusMapper(String? statusString) {
    if (statusString == null) {
      return RideTrackingStatus.initial;
    }

    return RideTrackingStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == statusString.toLowerCase(),
      orElse: () => RideTrackingStatus.initial,
    );
  }
}
