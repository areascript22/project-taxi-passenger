import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';

void main() {
  group('PlaceEntity.fromAutocomplete', () {
    test('parsea texto y placeId correctamente', () {
      final json = {
        'placePrediction': {
          'text': {'text': 'Av. Siempre Viva 123'},
          'placeId': 'abc123',
        },
      };

      final place = PlaceEntity.fromAutocomplete(json);

      expect(place.address, 'Av. Siempre Viva 123');
      expect(place.placeId, 'abc123');
      expect(place.formattedAddress, 'Av. Siempre Viva 123');
      expect(place.latitude, isNull);
      expect(place.longitude, isNull);
    });

    test('placeId null cuando no viene en el json', () {
      final json = {
        'placePrediction': {
          'text': {'text': 'Calle Falsa 456'},
        },
      };

      final place = PlaceEntity.fromAutocomplete(json);

      expect(place.address, 'Calle Falsa 456');
      expect(place.placeId, isNull);
    });
  });

  group('PlaceEntity.fromDetails', () {
    test('parsea address, coordenadas e id correctamente', () {
      final json = {
        'id': 'place-1',
        'formattedAddress': 'Av. Siempre Viva 123, Springfield',
        'location': {'latitude': -34.6, 'longitude': -58.4},
      };

      final place = PlaceEntity.fromDetails(json);

      expect(place.address, 'Av. Siempre Viva 123, Springfield');
      expect(place.formattedAddress, 'Av. Siempre Viva 123, Springfield');
      expect(place.placeId, 'place-1');
      expect(place.latitude, -34.6);
      expect(place.longitude, -58.4);
    });

    test('lat/lng quedan null cuando no viene location', () {
      final json = {'id': 'place-2', 'formattedAddress': 'Sin ubicación'};

      final place = PlaceEntity.fromDetails(json);

      expect(place.latitude, isNull);
      expect(place.longitude, isNull);
      expect(place.address, 'Sin ubicación');
    });

    test('address queda vacío cuando falta formattedAddress', () {
      final json = <String, dynamic>{};

      final place = PlaceEntity.fromDetails(json);

      expect(place.address, '');
      expect(place.placeId, isNull);
      expect(place.latitude, isNull);
      expect(place.longitude, isNull);
    });

    test('convierte valores numéricos enteros a double para lat/lng', () {
      final json = {
        'formattedAddress': 'Punto entero',
        'location': {'latitude': -34, 'longitude': -58},
      };

      final place = PlaceEntity.fromDetails(json);

      expect(place.latitude, -34.0);
      expect(place.longitude, -58.0);
    });
  });
}
