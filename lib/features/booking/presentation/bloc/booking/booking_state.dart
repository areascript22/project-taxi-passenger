part of 'booking_bloc.dart';

enum BookingStatus {
  initial,
  fetchingAddress,
  readyToBook,
  requestingTaxi,
  cancellingRequest,
  requestInQueue,
  searchingForDriver,
  // El punto elegido cayó fuera de los sectores de Riobamba: no es un error
  // (nada falló), es un punto que no se puede pedir. Tiene su propio status y
  // no un FailureCode porque no viene de una operación que salió mal.
  outOfCoverage,
  error,
}

@immutable
class BookingState {
  final BookingStatus status;
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;
  final String? destinationAddress;

  /// Sector de Riobamba del punto de recogida (ver shared/sectors/). Es lo que
  /// el conductor va a escuchar cuando entre la carrera, así que viaja hasta el
  /// backend junto con la dirección.
  ///
  /// `null` cuando el punto está fuera de cobertura, y también cuando el
  /// archivo de sectores no se pudo leer -- para distinguir esos dos casos está
  /// [isOutOfCoverage].
  final String? pickupSector;

  /// `true` solo cuando se verificó que el punto NO pertenece a ningún sector.
  /// Si la verificación no se pudo hacer (archivo ilegible) queda en `false`:
  /// se prefiere dejar pedir el taxi antes que bloquear la app entera por un
  /// asset roto, que afectaría al 100% de los usuarios.
  final bool isOutOfCoverage;

  final FailureCode? errorCode;

  const BookingState({
    this.status = BookingStatus.initial,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.destinationAddress,
    this.pickupSector,
    this.isOutOfCoverage = false,
    this.errorCode,
  });

  /// `true` si hay un punto de recogida completo y dentro de cobertura.
  bool get canRequestTaxi =>
      !isOutOfCoverage &&
      pickupLat != null &&
      pickupLng != null &&
      pickupAddress != null;

  BookingState copyWith({
    BookingStatus? status,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    String? destinationAddress,
    String? pickupSector,
    bool? isOutOfCoverage,
    FailureCode? errorCode,
    bool clearError = false,
    // Sin esto no hay forma de volver el sector a null con `??`: un punto fuera
    // de cobertura heredaría el sector del punto anterior y el conductor
    // escucharía un sector equivocado.
    bool clearPickupSector = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      pickupSector:
          clearPickupSector ? null : (pickupSector ?? this.pickupSector),
      isOutOfCoverage: isOutOfCoverage ?? this.isOutOfCoverage,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}
