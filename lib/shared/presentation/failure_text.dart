import 'package:flutter/widgets.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

/// Traduce un [FailureCode] al texto que se le muestra al usuario.
///
/// Es la contraparte de la regla de la capa de datos: los repositorios
/// devuelven codigos, y este es el unico lugar que decide el texto. Los
/// codigos que no son para mostrar (fallos de servicios internos que el
/// repositorio ya loguea, como el token de push) caen en el mensaje genarico
/// a proposito: si alguno llega a la UI por un camino nuevo, el usuario ve
/// algo razonable en vez de un detalle tecnico.
extension FailureTextX on BuildContext {
  String failureText(FailureCode code) {
    final l10n = AppLocalizations.of(this);
    return switch (code) {
      FailureCode.sessionVerifyFailed => l10n.failureSessionVerifyFailed,
      FailureCode.signInFailed => l10n.failureSignInFailed,
      FailureCode.signOutFailed => l10n.failureSignOutFailed,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.notSignedIn => l10n.failureUnexpected,
      FailureCode.notAuthenticated => l10n.failureNotAuthenticated,
      FailureCode.gpsDisabled => l10n.failureGpsDisabled,
      FailureCode.locationFetchFailed => l10n.failureLocationFetchFailed,
      FailureCode.addressNotFound => l10n.failureAddressNotFound,
      FailureCode.locationProcessFailed => l10n.failureLocationProcessFailed,
      FailureCode.networkError => l10n.failureNetworkError,
      FailureCode.mapsServerError => l10n.failureMapsServerError,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.mapsApiKeyMissing => l10n.failureUnexpected,
      FailureCode.placeSuggestionsFailed => l10n.failurePlaceSuggestionsFailed,
      FailureCode.placeDetailsFailed => l10n.failurePlaceDetailsFailed,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.placeIdMissing => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.placeWithoutCoordinates => l10n.failureUnexpected,
      FailureCode.rideRequestFailed => l10n.failureRideRequestFailed,
      FailureCode.rideRequestCancelFailed => l10n.failureRideRequestCancelFailed,
      FailureCode.rideRequestCancelUnavailable => l10n.failureRideRequestCancelUnavailable,
      FailureCode.rideCancelNotAllowed => l10n.failureRideCancelNotAllowed,
      FailureCode.rideCancelUnavailable => l10n.failureRideCancelUnavailable,
      FailureCode.rideCancelFailed => l10n.failureRideCancelFailed,
      FailureCode.activeTripCheckFailed => l10n.failureActiveTripCheckFailed,
      FailureCode.confirmFailed => l10n.failureConfirmFailed,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.initialDistanceFailed => l10n.failureUnexpected,
      FailureCode.chatWriteNotAllowed => l10n.failureChatWriteNotAllowed,
      FailureCode.chatRideFinished => l10n.failureChatRideFinished,
      FailureCode.chatSendFailed => l10n.failureChatSendFailed,
      FailureCode.accountHasActiveRide => l10n.failureAccountHasActiveRide,
      FailureCode.accountDeleteFailed => l10n.failureAccountDeleteFailed,
      FailureCode.passengerProfileCheckFailed => l10n.failurePassengerProfileCheckFailed,
      FailureCode.profileSaveFailed => l10n.failureProfileSaveFailed,
      FailureCode.profileUpdateFailed => l10n.failureProfileUpdateFailed,
      FailureCode.imagePickFailed => l10n.failureImagePickFailed,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushInitFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushTokenFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.fcmTokenSaveFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.pushLanguageSaveFailed => l10n.failureUnexpected,
      // solo para logs; si llega a la UI, mensaje genarico
      FailureCode.unexpectedUpstream => l10n.failureUnexpected,
      FailureCode.chatMessagesLoadFailed => l10n.failureChatMessagesLoadFailed,
      FailureCode.profileLoadFailed => l10n.failureProfileLoadFailed,
      FailureCode.locationPermissionDenied =>
        l10n.failureLocationPermissionDenied,
      FailureCode.unexpected => l10n.failureUnexpected,
    };
  }
}
