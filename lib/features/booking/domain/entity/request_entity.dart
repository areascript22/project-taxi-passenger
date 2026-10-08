class RequestEntity {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;

  /// Sector de Riobamba del punto de recogida (ver shared/sectors/). Es lo que
  /// el conductor escucha al entrar la carrera; la dirección exacta la ve
  /// recién al aceptarla.
  ///
  /// Puede ser `null` si no se pudo verificar la cobertura: en ese caso el
  /// backend lo guarda vacío y driver_app vuelve a leer la dirección completa,
  /// que es el comportamiento que había antes de los sectores.
  final String? pickupSector;

  const RequestEntity({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.pickupSector,
  });
}
