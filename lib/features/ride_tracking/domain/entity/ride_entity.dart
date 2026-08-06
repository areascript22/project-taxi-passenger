import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

class DriverEntity {
  final String name;
  final String photo;

  DriverEntity({required this.name, required this.photo});

  factory DriverEntity.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return DriverEntity(name: '', photo: '');

    return DriverEntity(
      name: json['displayName'] as String? ?? '',
      photo: json['photoUrl'] as String? ?? '',
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
    // El driver_app escribe la data del conductor anidada en driver.data
    final driverNode = json['driver'];
    final driverData =
        driverNode is Map ? driverNode['data'] as Map<dynamic, dynamic>? : null;

    return RideEntity(
      driver: DriverEntity.fromJson(driverData),
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
