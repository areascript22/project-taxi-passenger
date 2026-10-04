import 'dart:convert';

import '../domain/entity/sector_entity.dart';

/// Parseo y geometría de los sectores. Es lógica pura (sin Flutter, sin
/// AssetBundle, sin red) para que sea testeable directo: la parte frágil de
/// esto no es leer el archivo, es el orden de las coordenadas y los empates
/// entre polígonos solapados.
class SectorGeoJsonParser {
  SectorGeoJsonParser._();

  /// Mínimo de vértices para que un anillo encierre algo. Google My Maps puede
  /// exportar restos de dibujo (un punto, una línea) y no son sectores.
  static const int _minimumRingPoints = 3;

  /// Espacios "raros" que trae el archivo en algunos nombres ("Tierra nueva ",
  /// "Comil " con NBSP, "Los alamos  - Sesquicentenario" con doble espacio).
  /// Importa porque estos nombres los pronuncia un TTS, no son solo texto.
  static final RegExp _whitespaceRun = RegExp(r'[\s ]+');

  /// Convierte el GeoJSON crudo en sectores. Nunca lanza por features sueltas
  /// malformadas: las descarta y sigue, porque el archivo lo dibuja una persona
  /// a mano y un polígono roto no debe dejar la app sin cobertura entera.
  ///
  /// Soporta `Polygon` y `MultiPolygon`. Hoy el archivo trae solo `Polygon` con
  /// un anillo, pero si alguien lo vuelve a exportar desde My Maps y sale un
  /// `MultiPolygon`, se parte en un sector por polígono (mismo nombre) en vez
  /// de desaparecer en silencio.
  ///
  /// Los anillos interiores (huecos) se ignoran: el archivo no tiene ninguno, y
  /// asumir que el primero es el exterior es la convención de GeoJSON.
  static List<SectorEntity> parse({required String rawGeoJson}) {
    final decoded = jsonDecode(rawGeoJson);
    if (decoded is! Map<String, dynamic>) return const [];

    final features = decoded['features'];
    if (features is! List) return const [];

    final sectors = <SectorEntity>[];

    for (final feature in features) {
      if (feature is! Map) continue;

      final name = _readName(feature['properties']);
      if (name.isEmpty) continue;

      final geometry = feature['geometry'];
      if (geometry is! Map) continue;

      for (final ring in _outerRings(geometry)) {
        final points = _readRing(ring);
        if (points.length < _minimumRingPoints) continue;

        sectors.add(
          SectorEntity(
            name: name,
            ring: points,
            bounds: _boundsOf(points),
            area: _shoelaceArea(points),
          ),
        );
      }
    }

    return sectors;
  }

  /// El sector al que pertenece un punto, o `null` si está fuera de todos
  /// (= fuera de Riobamba, o un hueco del dibujo que hay que corregir en el
  /// `.geojson`).
  ///
  /// Con varios candidatos gana el de área menor: los polígonos se solapan y el
  /// más chico es el más específico ("Entrada medicina ESPOCH" antes que
  /// "Interior de la ESPOCH").
  static SectorEntity? sectorAt({
    required List<SectorEntity> sectors,
    required double latitude,
    required double longitude,
  }) {
    SectorEntity? best;

    for (final sector in sectors) {
      if (!_withinBounds(
        bounds: sector.bounds,
        latitude: latitude,
        longitude: longitude,
      )) {
        continue;
      }
      if (!_ringContains(
        ring: sector.ring,
        latitude: latitude,
        longitude: longitude,
      )) {
        continue;
      }
      if (best == null || sector.area < best.area) {
        best = sector;
      }
    }

    return best;
  }

  /// Caja que envuelve a TODOS los sectores: la zona de cobertura, usada para
  /// encuadrar el mapa y para restringir las sugerencias del buscador. `null`
  /// si no hay sectores (archivo vacío o ilegible).
  static SectorBounds? coverageBounds({required List<SectorEntity> sectors}) {
    if (sectors.isEmpty) return null;

    var minLatitude = sectors.first.bounds.minLatitude;
    var minLongitude = sectors.first.bounds.minLongitude;
    var maxLatitude = sectors.first.bounds.maxLatitude;
    var maxLongitude = sectors.first.bounds.maxLongitude;

    for (final sector in sectors.skip(1)) {
      if (sector.bounds.minLatitude < minLatitude) {
        minLatitude = sector.bounds.minLatitude;
      }
      if (sector.bounds.minLongitude < minLongitude) {
        minLongitude = sector.bounds.minLongitude;
      }
      if (sector.bounds.maxLatitude > maxLatitude) {
        maxLatitude = sector.bounds.maxLatitude;
      }
      if (sector.bounds.maxLongitude > maxLongitude) {
        maxLongitude = sector.bounds.maxLongitude;
      }
    }

    return SectorBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
    );
  }

  /// `true` si el punto está dentro de la caja de cobertura. Sirve para
  /// distinguir los dos casos que el usuario trata distinto: afuera de la caja
  /// es "no es Riobamba"; dentro de la caja pero sin sector es un hueco del
  /// dibujo.
  static bool isWithinBounds({
    required SectorBounds bounds,
    required double latitude,
    required double longitude,
  }) {
    return _withinBounds(
      bounds: bounds,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String _readName(Object? properties) {
    if (properties is! Map) return '';
    // El archivo usa "Name" (así lo exporta My Maps); se acepta "name" por si
    // una futura herramienta lo escribe en minúscula.
    final raw = properties['Name'] ?? properties['name'];
    if (raw is! String) return '';
    return raw.replaceAll(_whitespaceRun, ' ').trim();
  }

  static Iterable<List<dynamic>> _outerRings(Map geometry) {
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];

    if (type == 'Polygon' && coordinates is List && coordinates.isNotEmpty) {
      final outer = coordinates.first;
      return outer is List ? [outer] : const [];
    }

    if (type == 'MultiPolygon' && coordinates is List) {
      return coordinates
          .whereType<List>()
          .where((polygon) => polygon.isNotEmpty)
          .map((polygon) => polygon.first)
          .whereType<List>();
    }

    return const [];
  }

  // GeoJSON es [longitud, latitud] -- al revés de como se escribe un par de
  // coordenadas en todos lados. Invertirlo acá es la razón de que exista este
  // método en vez de leer los índices sueltos donde haga falta.
  static List<SectorPoint> _readRing(List<dynamic> ring) {
    final points = <SectorPoint>[];

    for (final pair in ring) {
      if (pair is! List || pair.length < 2) continue;
      final longitude = pair[0];
      final latitude = pair[1];
      if (longitude is! num || latitude is! num) continue;

      points.add(
        SectorPoint(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        ),
      );
    }

    return points;
  }

  static SectorBounds _boundsOf(List<SectorPoint> points) {
    var minLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLatitude = points.first.latitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLatitude) minLatitude = point.latitude;
      if (point.latitude > maxLatitude) maxLatitude = point.latitude;
      if (point.longitude < minLongitude) minLongitude = point.longitude;
      if (point.longitude > maxLongitude) maxLongitude = point.longitude;
    }

    return SectorBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: maxLatitude,
      maxLongitude: maxLongitude,
    );
  }

  static bool _withinBounds({
    required SectorBounds bounds,
    required double latitude,
    required double longitude,
  }) {
    return latitude >= bounds.minLatitude &&
        latitude <= bounds.maxLatitude &&
        longitude >= bounds.minLongitude &&
        longitude <= bounds.maxLongitude;
  }

  // Ray casting (crossing number): se cuenta cuántas veces un rayo horizontal
  // hacia el este cruza el borde. Impar = adentro.
  //
  // La comparación de latitudes es semiabierta a propósito (`>` en un extremo y
  // `<=` en el otro): así un vértice exactamente a la altura del rayo se cuenta
  // una sola vez y no dos, que es el bug clásico de esta función.
  static bool _ringContains({
    required List<SectorPoint> ring,
    required double latitude,
    required double longitude,
  }) {
    var inside = false;

    for (var current = 0, previous = ring.length - 1;
        current < ring.length;
        previous = current++) {
      final a = ring[current];
      final b = ring[previous];

      final straddles =
          (a.latitude > latitude) != (b.latitude > latitude);
      if (!straddles) continue;

      final crossingLongitude = a.longitude +
          (latitude - a.latitude) /
              (b.latitude - a.latitude) *
              (b.longitude - a.longitude);

      if (longitude < crossingLongitude) inside = !inside;
    }

    return inside;
  }

  static double _shoelaceArea(List<SectorPoint> points) {
    var sum = 0.0;

    for (var current = 0, previous = points.length - 1;
        current < points.length;
        previous = current++) {
      sum += points[previous].longitude * points[current].latitude -
          points[current].longitude * points[previous].latitude;
    }

    return sum.abs() / 2;
  }
}
