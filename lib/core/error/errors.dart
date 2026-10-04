/// Motivo por el que fallo una operacion, reportado por la capa de datos.
///
/// La capa de datos reporta QUE fallo, no QUE DECIRLE al usuario: el texto lo
/// resuelve la UI con `failureText` (ver shared/presentation/failure_text.dart),
/// que es la unica capa con acceso a AppLocalizations. Antes cada repositorio
/// construia su propio mensaje en espanol, lo que hacia imposible traducirlos
/// -- un repositorio no tiene BuildContext.
///
/// Varios motivos distintos a nivel de endpoint comparten codigo cuando el
/// usuario ve lo mismo (ej. todos los "no tenes permisos"). El detalle tecnico
/// de cada caso sigue quedando en el debugPrint del repositorio.
enum FailureCode {
  sessionVerifyFailed,
  signInFailed,
  signOutFailed,
  notSignedIn,
  notAuthenticated,
  gpsDisabled,
  locationFetchFailed,
  addressNotFound,
  locationProcessFailed,
  networkError,
  mapsServerError,
  mapsApiKeyMissing,
  placeSuggestionsFailed,
  placeDetailsFailed,
  placeIdMissing,
  placeWithoutCoordinates,
  rideRequestFailed,
  rideRequestCancelFailed,
  rideRequestCancelUnavailable,
  rideCancelNotAllowed,
  rideCancelUnavailable,
  rideCancelFailed,
  activeTripCheckFailed,
  confirmFailed,
  initialDistanceFailed,
  chatWriteNotAllowed,
  chatRideFinished,
  chatSendFailed,
  accountHasActiveRide,
  accountDeleteFailed,
  passengerProfileCheckFailed,
  profileSaveFailed,
  profileUpdateFailed,
  imagePickFailed,
  pushInitFailed,
  pushTokenFailed,
  fcmTokenSaveFailed,
  pushLanguageSaveFailed,
  unexpectedUpstream,
  chatMessagesLoadFailed,
  profileLoadFailed,
  locationPermissionDenied,
  unexpected,
}

abstract class ErrorBase {
  final FailureCode code;

  /// Detalle tecnico opcional (excepcion, codigo HTTP). Solo para logs: nunca
  /// se muestra al usuario.
  final String? detail;

  ErrorBase({required this.code, this.detail});
}

class Failure extends ErrorBase {
  Failure({required super.code, super.detail});
}
