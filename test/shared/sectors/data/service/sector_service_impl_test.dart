import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/sectors/data/service/sector_service_impl.dart';
import 'package:passenger_app/shared/sectors/utils/sector_geojson_parser.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle({this.payload, this.failure});

  final String? payload;
  final Object? failure;
  int loadCalls = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCalls++;
    if (failure != null) throw failure!;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload!)));
  }
}

String _squareCollection({
  required String name,
  required double latitude,
  required double longitude,
  double size = 0.01,
}) {
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {'Name': name},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [longitude, latitude],
              [longitude + size, latitude],
              [longitude + size, latitude + size],
              [longitude, latitude + size],
              [longitude, latitude],
            ],
          ],
        },
      },
    ],
  });
}

void main() {
  group('loadSectors', () {
    test('parsea el geojson del bundle', () async {
      final service = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(
          payload: _squareCollection(
            name: 'La Condamine',
            latitude: -1.67,
            longitude: -78.65,
          ),
        ),
      );

      final result = await service.loadSectors();

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse(() => []).single.name,
        'La Condamine',
      );
    });

    // El mapa consulta el sector en cada movimiento de cámara: volver a leer y
    // parsear el archivo en cada consulta sería un desperdicio notorio.
    test('lee y parsea el asset una sola vez', () async {
      final bundle = _FakeAssetBundle(
        payload: _squareCollection(
          name: 'La Condamine',
          latitude: -1.67,
          longitude: -78.65,
        ),
      );
      final service = SectorServiceImpl(assetBundle: bundle);

      await service.loadSectors();
      await service.loadSectors();
      await service.sectorFor(latitude: -1.665, longitude: -78.645);

      expect(bundle.loadCalls, 1);
    });

    test('devuelve Left si el asset no se puede leer', () async {
      final service = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(failure: Exception('sin asset')),
      );

      final result = await service.loadSectors();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.code, FailureCode.sectorsLoadFailed),
        (_) => fail('se esperaba Left'),
      );
    });

    // Un archivo presente pero ilegible dejaría a toda la ciudad "fuera de
    // cobertura" en silencio: se reporta como fallo para que el gate pueda
    // distinguirlo de un punto realmente fuera.
    test('un geojson sin sectores legibles es un fallo, no una lista vacia', () async {
      final service = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(
          payload: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );

      final result = await service.loadSectors();

      expect(result.isLeft(), isTrue);
    });
  });

  group('sectorFor', () {
    late SectorServiceImpl service;

    setUp(() {
      service = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(
          payload: _squareCollection(
            name: 'La Condamine',
            latitude: -1.67,
            longitude: -78.65,
          ),
        ),
      );
    });

    test('devuelve el sector cuando el punto cae adentro', () async {
      final result = await service.sectorFor(
        latitude: -1.665,
        longitude: -78.645,
      );

      expect(result.getOrElse(() => null)?.name, 'La Condamine');
    });

    // Fuera de cobertura NO es un error: es una respuesta válida que el gate
    // necesita poder distinguir de un fallo de lectura.
    test('devuelve Right(null) cuando el punto esta fuera de cobertura', () async {
      final result = await service.sectorFor(
        latitude: -0.1807,
        longitude: -78.4678,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    });

    test('propaga el Left si no se pudo leer el archivo', () async {
      final broken = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(failure: Exception('sin asset')),
      );

      final result = await broken.sectorFor(
        latitude: -1.665,
        longitude: -78.645,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('coverageBounds / isWithinCoverageBounds', () {
    late SectorServiceImpl service;

    setUp(() {
      service = SectorServiceImpl(
        assetBundle: _FakeAssetBundle(
          payload: _squareCollection(
            name: 'La Condamine',
            latitude: -1.67,
            longitude: -78.65,
          ),
        ),
      );
    });

    test('la caja envuelve al sector', () async {
      final bounds = await service.coverageBounds();

      expect(bounds.isRight(), isTrue);
      bounds.fold((_) => fail('se esperaba Right'), (value) {
        expect(value.minLatitude, closeTo(-1.67, 1e-9));
        expect(value.maxLongitude, closeTo(-78.64, 1e-9));
      });
    });

    test('distingue dentro y fuera de la caja', () async {
      final inside = await service.isWithinCoverageBounds(
        latitude: -1.665,
        longitude: -78.645,
      );
      final outside = await service.isWithinCoverageBounds(
        latitude: -0.1807,
        longitude: -78.4678,
      );

      expect(inside.getOrElse(() => false), isTrue);
      expect(outside.getOrElse(() => true), isFalse);
    });
  });

  // Estos tests leen el .geojson REAL del repo. No fijan la cantidad exacta de
  // sectores a propósito -- se espera que el archivo crezca y se corrija para
  // tapar huecos -- pero sí que siga siendo un archivo sano y que la cobertura
  // siga cayendo sobre Riobamba.
  group('sectors.geojson real', () {
    late List<dynamic> sectors;

    setUpAll(() async {
      final raw = await File('assets/json/sectors.geojson').readAsString();
      sectors = SectorGeoJsonParser.parse(rawGeoJson: raw);
    });

    test('se parsea y tiene una cantidad razonable de sectores', () {
      // Al escribir esto el archivo trae 59.
      expect(sectors.length, greaterThanOrEqualTo(40));
    });

    test('ningun sector queda sin nombre ni con un anillo degenerado', () {
      for (final sector in sectors.cast<dynamic>()) {
        expect(sector.name.trim(), isNotEmpty);
        expect(sector.name, sector.name.trim());
        expect(sector.ring.length, greaterThanOrEqualTo(3));
      }
    });

    test('la cobertura cae sobre Riobamba, no sobre el oceano', () {
      final bounds = SectorGeoJsonParser.coverageBounds(
        sectors: sectors.cast(),
      )!;

      // Riobamba está en ~(-1.66, -78.65). Si alguien invirtiera lat/lng al
      // parsear, estos rangos no se cumplirían.
      expect(bounds.minLatitude, inInclusiveRange(-1.80, -1.55));
      expect(bounds.maxLatitude, inInclusiveRange(-1.80, -1.55));
      expect(bounds.minLongitude, inInclusiveRange(-78.80, -78.55));
      expect(bounds.maxLongitude, inInclusiveRange(-78.80, -78.55));
    });

    test('un punto conocido de Riobamba resuelve a su sector', () {
      // Centroide del polígono "Multiplaza" del archivo real, que es el único
      // que lo contiene.
      final sector = SectorGeoJsonParser.sectorAt(
        sectors: sectors.cast(),
        latitude: -1.655975,
        longitude: -78.664241,
      );

      expect(sector?.name, 'Multiplaza');
    });

    test('Quito queda fuera de la cobertura', () {
      final sector = SectorGeoJsonParser.sectorAt(
        sectors: sectors.cast(),
        latitude: -0.1807,
        longitude: -78.4678,
      );

      expect(sector, isNull);
    });
  });
}
