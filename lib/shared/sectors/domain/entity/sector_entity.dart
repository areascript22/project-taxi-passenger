/// Un sector de Riobamba: el polígono dibujado a mano en
/// `assets/json/sectors.geojson` y el nombre que el conductor va a **escuchar**
/// cuando entre la carrera (ver driver_app, alerta hablada del isolate).
///
/// Los 59 sectores son, además, la zona de cobertura del servicio: un punto que
/// no cae en ninguno se considera fuera de Riobamba y no se puede pedir taxi
/// desde ahí.
class SectorEntity {
  final String name;

  /// Anillo exterior del polígono, ya convertido a (lat, lng). El GeoJSON los
  /// trae al revés -- `[lng, lat]` -- así que la conversión pasa una sola vez,
  /// acá, en vez de en cada comparación.
  final List<SectorPoint> ring;

  final SectorBounds bounds;

  /// Área en grados² (shoelace). No es una medida geográfica útil y no se
  /// muestra en ningún lado: sirve solo para comparar tamaños entre sectores.
  /// Los polígonos se solapan en varias zonas, y cuando un punto cae en dos
  /// gana el más chico, que es el más específico.
  final double area;

  const SectorEntity({
    required this.name,
    required this.ring,
    required this.bounds,
    required this.area,
  });
}

class SectorPoint {
  final double latitude;
  final double longitude;

  const SectorPoint({required this.latitude, required this.longitude});
}

/// Caja envolvente. Con un polígono acelera el descarte antes de correr ray
/// casting; con todos juntos (ver `SectorGeoJsonParser.coverageBounds`) es la
/// definición de "dónde queda Riobamba" que usan el mapa y el buscador, en vez
/// de las coordenadas hardcodeadas que había antes en dos archivos distintos.
class SectorBounds {
  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  const SectorBounds({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });
}
