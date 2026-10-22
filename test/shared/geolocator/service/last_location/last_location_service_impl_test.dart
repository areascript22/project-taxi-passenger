import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/domain/entity/user_location.dart';
import 'package:passenger_app/shared/geolocator/service/last_location/last_location_service_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LastLocationServiceImpl service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = LastLocationServiceImpl();
  });

  test('returns Right(null) when nothing has been saved yet', () async {
    final result = await service.getLastLocation();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => UserLocation(latitude: 9, longitude: 9)),
        isNull);
  });

  test('returns what was saved, even across service instances', () async {
    final saved = await service.saveLastLocation(
      location: UserLocation(latitude: -1.67, longitude: -78.65),
    );
    expect(saved.isRight(), isTrue);

    final result = await LastLocationServiceImpl().getLastLocation();

    final location = result.getOrElse(
      () => UserLocation(latitude: 9, longitude: 9),
    );
    expect(location!.latitude, -1.67);
    expect(location.longitude, -78.65);
  });

  test('a later save overwrites the previous one', () async {
    await service.saveLastLocation(
      location: UserLocation(latitude: 1, longitude: 2),
    );
    await service.saveLastLocation(
      location: UserLocation(latitude: 3, longitude: 4),
    );

    final location = (await service.getLastLocation()).getOrElse(
      () => UserLocation(latitude: 9, longitude: 9),
    );
    expect(location!.latitude, 3);
    expect(location.longitude, 4);
  });

  test('only one coordinate stored counts as nothing saved', () async {
    SharedPreferences.setMockInitialValues({'last_location_latitude': 1.0});

    final result = await LastLocationServiceImpl().getLastLocation();

    expect(
      result.getOrElse(() => UserLocation(latitude: 9, longitude: 9)),
      isNull,
    );
  });
}
