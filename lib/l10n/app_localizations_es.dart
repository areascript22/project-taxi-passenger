// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Taxi project';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionAppearance => 'APARIENCIA';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsSectionNotifications => 'NOTIFICACIONES';

  @override
  String get settingsVoiceTitle => 'Voz';

  @override
  String get settingsVoiceSubtitle => 'Anuncios hablados de la app';

  @override
  String get settingsVibrationTitle => 'Vibración';

  @override
  String get settingsVibrationSubtitle => 'Vibrar en eventos importantes';

  @override
  String get settingsSectionAccount => 'CUENTA';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountSubtitle => 'Esta acción no se puede deshacer';

  @override
  String get deleteAccountDialogBody => 'Esta acción es irreversible. Se eliminarán tu perfil, tu foto y tus chats. No podrás recuperar esta información.\n\n¿Seguro que deseas eliminar tu cuenta?';

  @override
  String get deleteAccountSuccess => 'Cuenta eliminada correctamente';

  @override
  String bookingCancelCountdown(String time) {
    return 'Cancelaremos en $time';
  }

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSignOut => 'Cerrar sesión';

  @override
  String get commonEmail => 'Correo electrónico';

  @override
  String get commonEmailShort => 'Correo';

  @override
  String get commonUnderstood => 'Entendido';

  @override
  String get commonPickupPoint => 'Punto de recogida';

  @override
  String get fieldFirstName => 'Nombres';

  @override
  String get fieldLastName => 'Apellidos';

  @override
  String get logoutDialogBody => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get navRequest => 'Pedir';

  @override
  String get navProfile => 'Perfil';

  @override
  String get photoSheetTitle => 'Foto de perfil';

  @override
  String get photoTakePhoto => 'Tomar foto';

  @override
  String get photoFromGallery => 'Elegir de galería';

  @override
  String get chatTitle => 'Chat con tu conductor';

  @override
  String get chatEmpty => 'Todavía no hay mensajes';

  @override
  String get chatInputHint => 'Escribe un mensaje...';

  @override
  String get sessionCheckFailed => 'No se pudo verificar tu sesión. Revisa tu conexión e intenta de nuevo.';

  @override
  String get signInWelcome => 'Bienvenido Pasajero';

  @override
  String get signInTagline => 'Viaja de forma segura y rápida con nosotros.';

  @override
  String get signInGoogle => 'Continuar con Google';

  @override
  String get bookingWhereTo => '¿A dónde vas?';

  @override
  String get bookingReadyToRide => '¿Listo para viajar?';

  @override
  String get bookingWelcomeAnnouncement => 'Bienvenido a TaxiGo';

  @override
  String get bookingRequestTaxi => 'Solicitar taxi';

  @override
  String get bookingCheckingPermissions => 'Comprobando permisos...';

  @override
  String get bookingGettingLocation => 'Obteniendo tu ubicación...';

  @override
  String get bookingGettingAddress => 'Obteniendo tu dirección...';

  @override
  String get bookingSearchHint => 'Buscar dirección o lugar...';

  @override
  String get bookingNoResults => 'No se encontraron resultados';

  @override
  String get bookingPickOnMap => 'Elegir en el mapa';

  @override
  String get bookingConfirmTitle => '¿Confirmar viaje?';

  @override
  String get bookingConfirmBody => 'Un conductor será enviado a la siguiente ubicación:';

  @override
  String get bookingRequest => 'Solicitar';

  @override
  String get locationWhereAreYou => '¿Dónde te encuentras?';

  @override
  String get waitingTitle => 'Buscando conductor...';

  @override
  String get waitingBody => 'Estamos buscando un taxi disponible para tu viaje. Por favor espera, un conductor aceptará tu solicitud en breve.';

  @override
  String get waitingRideAccepted => 'Carrera aceptada';

  @override
  String get waitingNoDrivers => 'Ahora mismo no hay conductores disponibles. Intenta de nuevo en unos minutos.';

  @override
  String get waitingCancelRequest => 'Cancelar solicitud';

  @override
  String get waitingAutoCancelFailed => 'No se pudo cancelar automáticamente. Intenta cancelar de nuevo.';

  @override
  String get waitingCancelFailed => 'No se pudo cancelar la solicitud. Intenta de nuevo.';

  @override
  String get onboardingTitle => 'Completa tu perfil';

  @override
  String get onboardingSubtitle => 'Cuéntanos quién eres para poder identificarte en tus viajes.';

  @override
  String get onboardingSignOutPrompt => '¿No eres tú? Cerrar sesión';

  @override
  String get profileEdit => 'Editar perfil';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get rideDriverCancelledAnnouncement => 'El conductor canceló el viaje';

  @override
  String get rideDriverArrivedAnnouncement => 'El conductor ha llegado';

  @override
  String get rideThanksAnnouncement => 'Taxi Go te agradece por elegir nuestros servicios.';

  @override
  String get rideYourTripTitle => 'Tu viaje';

  @override
  String get rideLoadingDriver => 'Buscando datos del conductor...';

  @override
  String get rideDriverOnTheWay => 'Tu conductor está en camino';

  @override
  String get rideLocationUnavailable => 'Ubicación no disponible';

  @override
  String get rideCancel => 'Cancelar viaje';

  @override
  String get rideArriving => 'Llegando';

  @override
  String rideEtaMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String rideDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String rideDistanceKilometers(String km) {
    return '$km km';
  }

  @override
  String get cancelRideDialogTitle => '¿Cancelar viaje?';

  @override
  String get cancelRideDialogBody => 'Tu conductor ya está en camino. Si cancelas ahora, es posible que se te aplique un cargo por cancelación.';

  @override
  String get cancelRideContinue => 'Continuar viaje';

  @override
  String get driverArrivedBody => 'Tu conductor te está esperando en el punto de recogida. Dirígete al vehículo.';

  @override
  String get driverArrivedConfirm => 'En camino';

  @override
  String get driverCancelledTitle => 'Viaje cancelado';

  @override
  String get driverCancelledBody => 'Tu conductor canceló el viaje. Puedes solicitar otro taxi cuando quieras.';

  @override
  String get tripCompletedTitle => 'Has llegado a tu destino';

  @override
  String get tripCompletedBody => 'Gracias por elegirnos. Esperamos verte pronto de nuevo.';

  @override
  String get distanceIndicatorTitle => 'El conductor está en camino';

  @override
  String get distanceIndicatorSubtitle => 'Su conductor se dirige al lugar de recogida.';

  @override
  String get distanceYourLocation => 'Tu ubicación';

  @override
  String get distanceDriver => 'Conductor';

  @override
  String get distanceLabel => 'Distancia';

  @override
  String get distanceEta => 'Tiempo estimado';

  @override
  String get mapPickerTitle => 'Selecciona tu ubicación';

  @override
  String get mapPickerConfirm => 'Confirmar ubicación';

  @override
  String get mapPickerSearching => 'Buscando dirección...';

  @override
  String get mapPickerAddressFailed => 'No se pudo obtener la dirección.';

  @override
  String get mapPickerHint => 'Mueve el mapa para elegir tu ubicación';

  @override
  String get commonNotProvided => 'No registrado';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaving => 'Guardando...';

  @override
  String get validationFirstName => 'Ingresa tus nombres';

  @override
  String get validationLastName => 'Ingresa tus apellidos';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get failureSessionVerifyFailed => 'No se pudo verificar tu sesión. Intenta de nuevo.';

  @override
  String get failureSignInFailed => 'No se pudo iniciar sesión. Intenta de nuevo.';

  @override
  String get failureSignOutFailed => 'No se pudo cerrar sesión. Intenta de nuevo.';

  @override
  String get failureNotAuthenticated => 'Tu sesión expiró. Inicia sesión de nuevo.';

  @override
  String get failureGpsDisabled => 'El servicio de GPS del dispositivo está desactivado.';

  @override
  String get failureLocationFetchFailed => 'No se pudo obtener tu ubicación. Intenta de nuevo.';

  @override
  String get failureAddressNotFound => 'No se pudo encontrar una dirección para esta ubicación.';

  @override
  String get failureLocationProcessFailed => 'Ocurrió un error inesperado al procesar la ubicación.';

  @override
  String get failureNetworkError => 'Revisa tu conexión a internet.';

  @override
  String get failureMapsServerError => 'No se pudo contactar al servicio de mapas. Intenta de nuevo.';

  @override
  String get failurePlaceSuggestionsFailed => 'No se pudieron buscar lugares. Intenta de nuevo.';

  @override
  String get failurePlaceDetailsFailed => 'No se pudo obtener el detalle del lugar. Intenta de nuevo.';

  @override
  String get failureRideRequestFailed => 'No se pudo solicitar el taxi. Intenta de nuevo.';

  @override
  String get failureRideRequestCancelFailed => 'No se pudo cancelar la solicitud. Intenta de nuevo.';

  @override
  String get failureRideRequestCancelUnavailable => 'La solicitud ya no está disponible para cancelar.';

  @override
  String get failureRideCancelNotAllowed => 'No tienes permiso para cancelar este viaje.';

  @override
  String get failureRideCancelUnavailable => 'El viaje ya no está disponible para cancelar.';

  @override
  String get failureRideCancelFailed => 'No se pudo cancelar el viaje. Intenta de nuevo.';

  @override
  String get failureActiveTripCheckFailed => 'No se pudo verificar si tienes un viaje en curso.';

  @override
  String get failureConfirmFailed => 'No se pudo confirmar. Intenta de nuevo.';

  @override
  String get failureChatWriteNotAllowed => 'No tienes permiso para escribir en este viaje.';

  @override
  String get failureChatRideFinished => 'El viaje ya finalizó, no se pueden enviar más mensajes.';

  @override
  String get failureChatSendFailed => 'No se pudo enviar el mensaje. Intenta de nuevo.';

  @override
  String get failureAccountHasActiveRide => 'Tienes un viaje activo. Finalízalo o cancélalo antes de eliminar tu cuenta.';

  @override
  String get failureAccountDeleteFailed => 'No se pudo eliminar tu cuenta. Intenta nuevamente.';

  @override
  String get failurePassengerProfileCheckFailed => 'No se pudo verificar tu información de pasajero';

  @override
  String get failureProfileSaveFailed => 'No se pudo guardar tu información. Intenta nuevamente.';

  @override
  String get failureProfileUpdateFailed => 'No se pudo actualizar tu información. Intenta nuevamente.';

  @override
  String get failureImagePickFailed => 'No se pudo obtener la imagen seleccionada';

  @override
  String get failureUnexpected => 'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String get failureChatMessagesLoadFailed => 'No se pudieron cargar los mensajes. Intenta de nuevo.';

  @override
  String get failureProfileLoadFailed => 'No se pudo cargar tu información';

  @override
  String get failureLocationPermissionDenied => 'No tienes permisos de ubicación.';

  @override
  String get settingsSectionLanguage => 'IDIOMA';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';
}
