import 'dart:math';

// Google Geocoding (reverse) devuelve, para una misma coordenada, un
// `results[]` con un candidato por cada nivel de granularidad disponible
// (calle, barrio, localidad, departamento, ...), ordenado de más a menos
// específico. El código anterior tomaba `results[0]` a ciegas -- en zonas
// rurales sin catastro digitalizado, ese primer resultado suele ser un Plus
// Code (`types: ["plus_code"]`, ej. "PJ23+AS34 Choluteca, Honduras"), que
// driver_app lee tal cual por voz al anunciar la carrera. Este parser elige
// el mejor candidato hablable y, si solo hay un nivel administrativo (sin
// calle/barrio), sintetiza una referencia por distancia y rumbo en vez de
// devolver ese nombre de localidad pelado (ambiguo para ubicar un punto
// dentro de todo un departamento).
class GeocodingResultParser {
  GeocodingResultParser._();

  static const List<String> _preciseTypes = [
    'street_address',
    'premise',
    'route',
    'intersection',
    'neighborhood',
    'sublocality',
    'sublocality_level_1',
  ];

  static const List<String> _coarseTypes = [
    'locality',
    'administrative_area_level_2',
    'administrative_area_level_1',
  ];

  static final RegExp _plusCodePrefix = RegExp(
    r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3}[,\s]*',
    caseSensitive: false,
  );

  static const double _fallbackDistanceThresholdKm = 1.0;

  static const List<String> _bearingLabels = [
    'norte',
    'noreste',
    'este',
    'sureste',
    'sur',
    'suroeste',
    'oeste',
    'noroeste',
  ];

  /// Elige la mejor dirección hablable a partir de los `results` crudos de la
  /// Geocoding API de Google para el punto (`latitude`, `longitude`)
  /// consultado. Devuelve `null` si no hay nada usable, ni siquiera un nivel
  /// administrativo con el que armar una referencia por distancia.
  static String? pickBestAddress({
    required List<dynamic> results,
    required double latitude,
    required double longitude,
  }) {
    final precise = _firstCleanMatch(results: results, types: _preciseTypes);
    if (precise != null) return precise;

    return _synthesizeFromCoarseMatch(
      results: results,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String? _firstCleanMatch({
    required List<dynamic> results,
    required List<String> types,
  }) {
    for (final type in types) {
      final match = _firstResultOfType(results, type);
      if (match == null) continue;

      final cleaned = _stripPlusCode(match['formatted_address'] as String? ?? '');
      if (cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  static String? _synthesizeFromCoarseMatch({
    required List<dynamic> results,
    required double latitude,
    required double longitude,
  }) {
    for (final type in _coarseTypes) {
      final match = _firstResultOfType(results, type);
      if (match == null) continue;

      final name = _stripPlusCode(match['formatted_address'] as String? ?? '');
      if (name.isEmpty) continue;

      final location = match['geometry']?['location'];
      final refLat = (location?['lat'] as num?)?.toDouble();
      final refLng = (location?['lng'] as num?)?.toDouble();
      if (refLat == null || refLng == null) return name;

      final distanceKm = _haversineKm(latitude, longitude, refLat, refLng);
      if (distanceKm < _fallbackDistanceThresholdKm) return name;

      final bearing = _bearingLabel(
        fromLat: refLat,
        fromLng: refLng,
        toLat: latitude,
        toLng: longitude,
      );
      return 'A ${distanceKm.toStringAsFixed(1)} km al $bearing de $name';
    }
    return null;
  }

  static Map<String, dynamic>? _firstResultOfType(
    List<dynamic> results,
    String type,
  ) {
    for (final result in results) {
      final types = (result['types'] as List<dynamic>?)?.cast<String>() ?? const [];
      if (types.contains(type) && !types.contains('plus_code')) {
        return result as Map<String, dynamic>;
      }
    }
    return null;
  }

  static String _stripPlusCode(String address) {
    return address.replaceFirst(_plusCodePrefix, '').trim();
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String _bearingLabel({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final dLng = _degToRad(toLng - fromLng);
    final fromLatRad = _degToRad(fromLat);
    final toLatRad = _degToRad(toLat);

    final y = sin(dLng) * cos(toLatRad);
    final x = cos(fromLatRad) * sin(toLatRad) -
        sin(fromLatRad) * cos(toLatRad) * cos(dLng);
    final bearingDeg = (_radToDeg(atan2(y, x)) + 360) % 360;

    final index = ((bearingDeg + 22.5) / 45).floor() % 8;
    return _bearingLabels[index];
  }

  static double _degToRad(double deg) => deg * (pi / 180);
  static double _radToDeg(double rad) => rad * (180 / pi);
}
