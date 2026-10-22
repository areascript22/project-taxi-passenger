import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/geocoding/utils/geocoding_result_parser.dart';

Map<String, dynamic> _result({
  required List<String> types,
  required String formattedAddress,
  double? lat,
  double? lng,
}) {
  return {
    'types': types,
    'formatted_address': formattedAddress,
    if (lat != null && lng != null)
      'geometry': {
        'location': {'lat': lat, 'lng': lng},
      },
  };
}

void main() {
  group('GeocodingResultParser.pickBestAddress', () {
    test('returns null when results is empty', () {
      final address = GeocodingResultParser.pickBestAddress(
        results: const [],
        latitude: 14.0,
        longitude: -88.0,
      );

      expect(address, isNull);
    });

    test('prefers street_address over a plus_code and a locality result', () {
      final results = [
        _result(
          types: const ['plus_code'],
          formattedAddress: 'GX7Q+2X Choluteca, Honduras',
        ),
        _result(
          types: const ['locality', 'political'],
          formattedAddress: 'Choluteca, Honduras',
          lat: 13.3,
          lng: -87.19,
        ),
        _result(
          types: const ['street_address'],
          formattedAddress: 'Calle Morazán, Choluteca, Honduras',
        ),
      ];

      final address = GeocodingResultParser.pickBestAddress(
        results: results,
        latitude: 13.301,
        longitude: -87.191,
      );

      expect(address, 'Calle Morazán, Choluteca, Honduras');
    });

    test('skips plus_code and falls back to route when no street_address exists', () {
      final results = [
        _result(
          types: const ['plus_code'],
          formattedAddress: 'GX7Q+2X Choluteca, Honduras',
        ),
        _result(
          types: const ['route'],
          formattedAddress: 'Carretera Panamericana, Choluteca, Honduras',
        ),
      ];

      final address = GeocodingResultParser.pickBestAddress(
        results: results,
        latitude: 13.301,
        longitude: -87.191,
      );

      expect(address, 'Carretera Panamericana, Choluteca, Honduras');
    });

    test('strips a plus-code prefix embedded in an otherwise usable result', () {
      // Alfabeto real de Open Location Code: "23456789CFGHJMPQRVWX" (sin
      // A/S/E/I/O/U ni otras letras ambiguas) -- "GX7Q+2X" es un código
      // válido, a diferencia de ejemplos inventados con letras fuera de ese
      // alfabeto.
      final results = [
        _result(
          types: const ['neighborhood', 'political'],
          formattedAddress: 'GX7Q+2X Barrio El Centro, Choluteca, Honduras',
        ),
      ];

      final address = GeocodingResultParser.pickBestAddress(
        results: results,
        latitude: 13.301,
        longitude: -87.191,
      );

      expect(address, 'Barrio El Centro, Choluteca, Honduras');
    });

    test(
      'synthesizes a distance + bearing reference when only a coarse (locality) '
      'level is available and the point is far from its centroid',
      () {
        final results = [
          _result(
            types: const ['locality', 'political'],
            formattedAddress: 'Choluteca, Honduras',
            lat: 14.0,
            lng: -88.0,
          ),
        ];

        // ~0.05 deg north of the locality centroid, same longitude -> ~5.6 km due north.
        final address = GeocodingResultParser.pickBestAddress(
          results: results,
          latitude: 14.05,
          longitude: -88.0,
        );

        expect(address, 'A 5.6 km al norte de Choluteca, Honduras');
      },
    );

    test(
      'returns the bare coarse-level name when the point is within 1 km of its centroid',
      () {
        final results = [
          _result(
            types: const ['locality', 'political'],
            formattedAddress: 'Choluteca, Honduras',
            lat: 14.0,
            lng: -88.0,
          ),
        ];

        // ~0.005 deg north -> ~0.56 km, below the 1 km threshold.
        final address = GeocodingResultParser.pickBestAddress(
          results: results,
          latitude: 14.005,
          longitude: -88.0,
        );

        expect(address, 'Choluteca, Honduras');
      },
    );

    test('returns the coarse-level name as-is when it has no geometry to measure from', () {
      final results = [
        _result(
          types: const ['administrative_area_level_1', 'political'],
          formattedAddress: 'Choluteca, Honduras',
        ),
      ];

      final address = GeocodingResultParser.pickBestAddress(
        results: results,
        latitude: 13.301,
        longitude: -87.191,
      );

      expect(address, 'Choluteca, Honduras');
    });

    test('returns null when only a country-level result is available', () {
      final results = [
        _result(
          types: const ['country', 'political'],
          formattedAddress: 'Honduras',
          lat: 15.2,
          lng: -86.2,
        ),
      ];

      final address = GeocodingResultParser.pickBestAddress(
        results: results,
        latitude: 13.301,
        longitude: -87.191,
      );

      expect(address, isNull);
    });
  });
}
