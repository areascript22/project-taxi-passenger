import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

void main() {
  group('DriverEntity.fromJson', () {
    test('json null devuelve DriverEntity vacío', () {
      final driver = DriverEntity.fromJson(null);

      expect(driver.name, '');
      expect(driver.photo, '');
      expect(driver.phoneNumber, '');
      expect(driver.vehiclePlate, '');
      expect(driver.vehicleBrand, '');
      expect(driver.vehicleModel, '');
      expect(driver.vehicleColor, '');
      expect(driver.latitude, isNull);
      expect(driver.longitude, isNull);
    });

    test('parsea data y location anidados, incluyendo teléfono y vehículo', () {
      final driver = DriverEntity.fromJson({
        'data': {
          'displayName': 'Juan Pérez',
          'photoUrl': 'http://x/p.png',
          'phoneNumber': '099123456',
          'vehiclePlate': 'ABC-1234',
          'vehicleBrand': 'Toyota',
          'vehicleModel': 'Corolla',
          'vehicleColor': 'Blanco',
        },
        'location': {'latitude': -34.1, 'longitude': -58.2},
      });

      expect(driver.name, 'Juan Pérez');
      expect(driver.photo, 'http://x/p.png');
      expect(driver.phoneNumber, '099123456');
      expect(driver.vehiclePlate, 'ABC-1234');
      expect(driver.vehicleBrand, 'Toyota');
      expect(driver.vehicleModel, 'Corolla');
      expect(driver.vehicleColor, 'Blanco');
      expect(driver.latitude, -34.1);
      expect(driver.longitude, -58.2);
    });

    test('data/location ausentes caen a valores por defecto', () {
      final driver = DriverEntity.fromJson({});

      expect(driver.name, '');
      expect(driver.photo, '');
      expect(driver.phoneNumber, '');
      expect(driver.vehiclePlate, '');
      expect(driver.vehicleBrand, '');
      expect(driver.vehicleModel, '');
      expect(driver.vehicleColor, '');
      expect(driver.latitude, isNull);
      expect(driver.longitude, isNull);
    });

    test('vehiculo ausente en data cae a valores por defecto', () {
      final driver = DriverEntity.fromJson({
        'data': {'displayName': 'Ana', 'photoUrl': 'p.png'},
      });

      expect(driver.vehiclePlate, '');
      expect(driver.vehicleBrand, '');
      expect(driver.vehicleModel, '');
      expect(driver.vehicleColor, '');
    });
  });

  group('RideEntity.fromJson', () {
    test('mapea un ride completo con status conocido', () {
      final ride = RideEntity.fromJson({
        'status': 'driverAssigned',
        'rideId': 'p1_1234567890',
        'cancelledBy': null,
        'driver': {
          'data': {'displayName': 'Ana', 'photoUrl': 'p.png'},
          'location': {'latitude': 1.0, 'longitude': 2.0},
          'initialDistance': 1500,
        },
        'pickupLocation': {
          'latitude': 10.0,
          'longitude': 20.0,
          'address': 'Calle 1',
        },
        'createdAt': 1234567890,
      });

      expect(ride.rideStatus, RideTrackingStatus.driverAssigned);
      expect(ride.rideId, 'p1_1234567890');
      expect(ride.driver.name, 'Ana');
      expect(ride.driver.latitude, 1.0);
      expect(ride.pickupLatitude, 10.0);
      expect(ride.pickupLongitude, 20.0);
      expect(ride.pickupAddress, 'Calle 1');
      expect(ride.driverInitialDistanceMeters, 1500.0);
      expect(ride.createdAtMillis, 1234567890);
    });

    test('status "pending" (sin enum homónimo) mapea a waitingDriver', () {
      final ride = RideEntity.fromJson({'status': 'pending'});

      expect(ride.rideStatus, RideTrackingStatus.waitingDriver);
    });

    test('status desconocido cae a initial', () {
      final ride = RideEntity.fromJson({'status': 'algo_que_no_existe'});

      expect(ride.rideStatus, RideTrackingStatus.initial);
    });

    test('status null cae a initial', () {
      final ride = RideEntity.fromJson({});

      expect(ride.rideStatus, RideTrackingStatus.initial);
    });

    test('rideId ausente queda en null', () {
      final ride = RideEntity.fromJson({'status': 'driverAssigned'});

      expect(ride.rideId, isNull);
    });

    test('status es case-insensitive', () {
      final ride = RideEntity.fromJson({'status': 'TRIPSTARTED'});

      expect(ride.rideStatus, RideTrackingStatus.tripStarted);
    });

    test('cancelledBy se propaga cuando está presente', () {
      final ride = RideEntity.fromJson({
        'status': 'cancelled',
        'cancelledBy': 'driver',
      });

      expect(ride.rideStatus, RideTrackingStatus.cancelled);
      expect(ride.cancelledBy, 'driver');
    });

    test('pickupLocation ausente deja lat/lng/address en null', () {
      final ride = RideEntity.fromJson({'status': 'driverAssigned'});

      expect(ride.pickupLatitude, isNull);
      expect(ride.pickupLongitude, isNull);
      expect(ride.pickupAddress, isNull);
    });

    test('driver ausente produce un DriverEntity vacío sin lanzar', () {
      final ride = RideEntity.fromJson({'status': 'driverAssigned'});

      expect(ride.driver.name, '');
      expect(ride.driverInitialDistanceMeters, isNull);
    });
  });
}
