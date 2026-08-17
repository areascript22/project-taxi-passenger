import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

class DriverEntity {
  final String name;
  final String photo;
  final double? latitude;
  final double? longitude;

  DriverEntity({
    required this.name,
    required this.photo,
    this.latitude,
    this.longitude,
  });

  factory DriverEntity.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return DriverEntity(name: '', photo: '');

    final data = json['data'] as Map<dynamic, dynamic>?;
    final location = json['location'] as Map<dynamic, dynamic>?;

    return DriverEntity(
      name: data?['displayName'] as String? ?? '',
      photo: data?['photoUrl'] as String? ?? '',
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
    );
  }
}

class RideEntity {
  final DriverEntity driver;
  final RideTrackingStatus rideStatus;
  // Quién canceló el viaje ('passenger' | 'driver'), solo relevante cuando
  // rideStatus == cancelled.
  final String? cancelledBy;
  // Punto que el pasajero eligió al pedir el taxi -- fijo durante todo el
  // viaje, se usa como referencia para calcular distancia/ETA/progreso.
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupAddress;
  // Distancia (metros) del conductor al punto de recogida en el momento en
  // que se lo detectó por primera vez -- referencia fija ("100%") para
  // normalizar DriverDistanceIndicator. Se escribe una sola vez desde
  // RideTrackingBloc (ver RideTrackingRepository.recordInitialDriverDistance).
  final double? driverInitialDistanceMeters;

  RideEntity({
    required this.driver,
    this.rideStatus = RideTrackingStatus.initial,
    this.cancelledBy,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupAddress,
    this.driverInitialDistanceMeters,
  });

  factory RideEntity.fromJson(Map<String, dynamic> json) {
    // El driver_app escribe la data y la ubicación del conductor anidadas
    // en driver.data / driver.location.
    final driverNode = json['driver'];
    final driverMap =
        driverNode is Map ? Map<dynamic, dynamic>.from(driverNode) : null;

    final pickupNode = json['pickupLocation'];
    final pickupMap =
        pickupNode is Map ? Map<dynamic, dynamic>.from(pickupNode) : null;

    return RideEntity(
      driver: DriverEntity.fromJson(driverMap),
      rideStatus: _statusMapper(json['status'] as String?),
      cancelledBy: json['cancelledBy'] as String?,
      pickupLatitude: (pickupMap?['latitude'] as num?)?.toDouble(),
      pickupLongitude: (pickupMap?['longitude'] as num?)?.toDouble(),
      pickupAddress: pickupMap?['address'] as String?,
      driverInitialDistanceMeters:
          (driverMap?['initialDistance'] as num?)?.toDouble(),
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
