import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/sectors/utils/sector_geojson_parser.dart';

// Cuadrado de 0.01 grados (~1.1 km) con la esquina inferior izquierda en
// (lat, lng). Se escribe en el orden de GeoJSON -- [lng, lat] -- porque eso es
// justo lo que estos tests tienen que blindar.
Map<String, dynamic> _square({
  required String name,
  required double latitude,
  required double longitude,
  double size = 0.01,
}) {
  return {
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
  };
}

String _collection(List<Map<String, dynamic>> features) {
  return jsonEncode({'type': 'FeatureCollection', 'features': features});
}

void main() {
  group('parse', () {
    test('lee el nombre y el anillo invirtiendo [lng, lat] a (lat, lng)', () {
      final sectors = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          _square(name: 'La Condamine', latitude: -1.67, longitude: -78.65),
        ]),
      );

      expect(sectors, hasLength(1));
      expect(sectors.single.name, 'La Condamine');
      // Si alguien invierte el orden al leer, esto queda en (-78.65, -1.67):
      // una coordenada en medio del Atlántico.
      expect(sectors.single.ring.first.latitude, closeTo(-1.67, 1e-9));
      expect(sectors.single.ring.first.longitude, closeTo(-78.65, 1e-9));
    });

    // Los nombres los pronuncia el TTS del conductor, y el archivo real trae
    // "Tierra nueva ", "Comil " (con espacio no separable) y
    // "Los alamos  - Sesquicentenario" (doble espacio).
    test('normaliza los espacios sucios de los nombres', () {
      final sectors = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          _square(name: 'Tierra nueva ', latitude: -1.67, longitude: -78.65),
          _square(name: 'Comil ', latitude: -1.60, longitude: -78.60),
          _square(
            name: 'Los alamos  - Sesquicentenario',
            latitude: -1.50,
            longitude: -78.50,
          ),
        ]),
      );

      expect(
        sectors.map((sector) => sector.name),
        ['Tierra nueva', 'Comil', 'Los alamos - Sesquicentenario'],
      );
    });

    test('calcula bounds y area del anillo', () {
      final sector = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          _square(name: 'Cuadrado', latitude: -1.67, longitude: -78.65),
        ]),
      ).single;

      expect(sector.bounds.minLatitude, closeTo(-1.67, 1e-9));
      expect(sector.bounds.maxLatitude, closeTo(-1.66, 1e-9));
      expect(sector.bounds.minLongitude, closeTo(-78.65, 1e-9));
      expect(sector.bounds.maxLongitude, closeTo(-78.64, 1e-9));
      expect(sector.area, closeTo(0.0001, 1e-12));
    });

    // El .geojson lo dibuja una persona a mano en My Maps: un resto de dibujo
    // no debe tirar abajo la cobertura de toda la ciudad.
    test('descarta features malformadas y sigue con el resto', () {
      final sectors = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          {'type': 'Feature', 'properties': {}, 'geometry': null},
          {
            'type': 'Feature',
            'properties': {'Name': 'Sin nombre util'},
            'geometry': {'type': 'LineString', 'coordinates': []},
          },
          {
            'type': 'Feature',
            'properties': {'Name': 'Dos puntos no encierran nada'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-78.65, -1.67],
                  [-78.64, -1.67],
                ],
              ],
            },
          },
          _square(name: 'Valido', latitude: -1.67, longitude: -78.65),
        ]),
      );

      expect(sectors.map((sector) => sector.name), ['Valido']);
    });

    test('un MultiPolygon se parte en un sector por poligono', () {
      final sectors = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          {
            'type': 'Feature',
            'properties': {'Name': 'Dos pedazos'},
            'geometry': {
              'type': 'MultiPolygon',
              'coordinates': [
                [
                  [
                    [-78.65, -1.67],
                    [-78.64, -1.67],
                    [-78.64, -1.66],
                    [-78.65, -1.67],
                  ],
                ],
                [
                  [
                    [-78.60, -1.60],
                    [-78.59, -1.60],
                    [-78.59, -1.59],
                    [-78.60, -1.60],
                  ],
                ],
              ],
            },
          },
        ]),
      );

      expect(sectors, hasLength(2));
      expect(sectors.every((sector) => sector.name == 'Dos pedazos'), isTrue);
    });

    test('un json que no es una FeatureCollection devuelve vacio', () {
      expect(SectorGeoJsonParser.parse(rawGeoJson: '[]'), isEmpty);
      expect(SectorGeoJsonParser.parse(rawGeoJson: '{}'), isEmpty);
    });
  });

  group('sectorAt', () {
    final sectors = SectorGeoJsonParser.parse(
      rawGeoJson: _collection([
        _square(name: 'Grande', latitude: -1.67, longitude: -78.65, size: 0.02),
        // Contenido dentro de 'Grande': el caso de solape real del archivo
        // (ej. "Entrada medicina ESPOCH" dentro de "Interior de la ESPOCH").
        _square(name: 'Chico', latitude: -1.665, longitude: -78.645, size: 0.005),
        _square(name: 'Lejano', latitude: -1.50, longitude: -78.50),
      ]),
    );

    SectorEntity? at(double latitude, double longitude) =>
        SectorGeoJsonParser.sectorAt(
          sectors: sectors,
          latitude: latitude,
          longitude: longitude,
        );

    test('un punto claramente adentro devuelve su sector', () {
      expect(at(-1.669, -78.649)?.name, 'Grande');
      expect(at(-1.495, -78.495)?.name, 'Lejano');
    });

    test('un punto fuera de todos los poligonos devuelve null', () {
      // Quito, bien lejos de Riobamba.
      expect(at(-0.1807, -78.4678), isNull);
      // Justo al lado del cuadrado 'Grande' pero afuera.
      expect(at(-1.671, -78.651), isNull);
    });

    test('con solape gana el poligono mas chico (el mas especifico)', () {
      expect(at(-1.663, -78.643)?.name, 'Chico');
    });

    test('un punto apenas adentro del borde sigue contando como adentro', () {
      // ~0.1 m dentro del borde sur del cuadrado 'Grande'.
      expect(at(-1.669999, -78.649)?.name, 'Grande');
    });

    test('sin sectores no explota: devuelve null', () {
      expect(
        SectorGeoJsonParser.sectorAt(
          sectors: const [],
          latitude: -1.67,
          longitude: -78.65,
        ),
        isNull,
      );
    });
  });

  group('coverageBounds', () {
    test('envuelve a todos los sectores', () {
      final sectors = SectorGeoJsonParser.parse(
        rawGeoJson: _collection([
          _square(name: 'Sur', latitude: -1.70, longitude: -78.70),
          _square(name: 'Norte', latitude: -1.60, longitude: -78.60),
        ]),
      );

      final bounds = SectorGeoJsonParser.coverageBounds(sectors: sectors)!;

      expect(bounds.minLatitude, closeTo(-1.70, 1e-9));
      expect(bounds.maxLatitude, closeTo(-1.59, 1e-9));
      expect(bounds.minLongitude, closeTo(-78.70, 1e-9));
      expect(bounds.maxLongitude, closeTo(-78.59, 1e-9));
    });

    test('sin sectores devuelve null', () {
      expect(SectorGeoJsonParser.coverageBounds(sectors: const []), isNull);
    });
  });

  group('isWithinBounds', () {
    const bounds = SectorBounds(
      minLatitude: -1.70,
      minLongitude: -78.70,
      maxLatitude: -1.60,
      maxLongitude: -78.60,
    );

    // Esta es la distinción que el usuario trata distinto: un punto dentro de
    // la caja pero sin sector es un HUECO del dibujo (hay que corregir el
    // .geojson); uno fuera de la caja simplemente no es Riobamba.
    test('distingue dentro de la caja de cobertura y fuera', () {
      expect(
        SectorGeoJsonParser.isWithinBounds(
          bounds: bounds,
          latitude: -1.65,
          longitude: -78.65,
        ),
        isTrue,
      );
      expect(
        SectorGeoJsonParser.isWithinBounds(
          bounds: bounds,
          latitude: -0.1807,
          longitude: -78.4678,
        ),
        isFalse,
      );
    });
  });
}
