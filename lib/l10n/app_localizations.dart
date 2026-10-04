import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Nombre de la app que ve el sistema operativo (ej. el selector de apps de Android)
  ///
  /// In es, this message translates to:
  /// **'Taxi project'**
  String get appTitle;

  /// Botón para descartar una acción, compartido por varios diálogos
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// Título del AppBar de la pantalla de ajustes
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Encabezado de sección. Va en mayúsculas a propósito (estilo visual de la pantalla), no es un grito
  ///
  /// In es, this message translates to:
  /// **'APARIENCIA'**
  String get settingsSectionAppearance;

  /// Opción de tema oscuro
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// Opción de tema claro
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// Opción de tema que sigue al sistema operativo
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// Encabezado de sección, en mayúsculas por estilo visual
  ///
  /// In es, this message translates to:
  /// **'NOTIFICACIONES'**
  String get settingsSectionNotifications;

  /// Switch que activa los anuncios hablados (TTS)
  ///
  /// In es, this message translates to:
  /// **'Voz'**
  String get settingsVoiceTitle;

  /// Descripción del switch de voz
  ///
  /// In es, this message translates to:
  /// **'Anuncios hablados de la app'**
  String get settingsVoiceSubtitle;

  /// Switch que activa la vibración
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get settingsVibrationTitle;

  /// Descripción del switch de vibración
  ///
  /// In es, this message translates to:
  /// **'Vibrar en eventos importantes'**
  String get settingsVibrationSubtitle;

  /// Encabezado de sección, en mayúsculas por estilo visual
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get settingsSectionAccount;

  /// Usado en el tile de ajustes, en el título del diálogo de confirmación y en su botón de confirmar
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccountTitle;

  /// Subtítulo del tile de eliminar cuenta en ajustes
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer'**
  String get deleteAccountSubtitle;

  /// Cuerpo del diálogo de confirmación. A diferencia de driver_app no menciona vehículo, porque el pasajero no tiene uno registrado
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible. Se eliminarán tu perfil, tu foto y tus chats. No podrás recuperar esta información.\n\n¿Seguro que deseas eliminar tu cuenta?'**
  String get deleteAccountDialogBody;

  /// Toast de éxito tras eliminar la cuenta, justo antes del logout
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada correctamente'**
  String get deleteAccountSuccess;

  /// Cuenta atrás en el popup de 'Buscando conductor': avisa cuánto falta para que la solicitud se cancele automáticamente
  ///
  /// In es, this message translates to:
  /// **'Cancelaremos en {time}'**
  String bookingCancelCountdown(String time);

  /// Boton para reintentar una operacion que fallo
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// Accion de cerrar sesion: titulo del dialogo, su boton, y el boton del perfil
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get commonSignOut;

  /// Etiqueta del campo de correo
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get commonEmail;

  /// Version corta de la etiqueta de correo, usada en la vista de perfil
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get commonEmailShort;

  /// Boton que solo cierra un dialogo informativo
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonUnderstood;

  /// Etiqueta del punto donde el conductor recoge al pasajero
  ///
  /// In es, this message translates to:
  /// **'Punto de recogida'**
  String get commonPickupPoint;

  /// Etiqueta del campo de nombres
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get fieldFirstName;

  /// Etiqueta del campo de apellidos
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get fieldLastName;

  /// Cuerpo del dialogo de confirmacion de cierre de sesion
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get logoutDialogBody;

  /// Pestania del bottom nav para pedir un taxi
  ///
  /// In es, this message translates to:
  /// **'Pedir'**
  String get navRequest;

  /// Pestania del bottom nav del perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// Titulo del bottom sheet para elegir el origen de la foto
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get photoSheetTitle;

  /// Opcion de usar la camara
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get photoTakePhoto;

  /// Opcion de elegir una foto existente
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get photoFromGallery;

  /// Titulo del AppBar del chat y etiqueta del boton de chat en el viaje
  ///
  /// In es, this message translates to:
  /// **'Chat con tu conductor'**
  String get chatTitle;

  /// Mensaje cuando la conversacion esta vacia
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mensajes'**
  String get chatEmpty;

  /// Placeholder del campo de texto del chat
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get chatInputHint;

  /// Mensaje cuando falla el chequeo de sesion
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu sesión. Revisa tu conexión e intenta de nuevo.'**
  String get sessionCheckFailed;

  /// Titulo de la pantalla de login
  ///
  /// In es, this message translates to:
  /// **'Bienvenido Pasajero'**
  String get signInWelcome;

  /// Frase bajo el titulo en el login
  ///
  /// In es, this message translates to:
  /// **'Viaja de forma segura y rápida con nosotros.'**
  String get signInTagline;

  /// Boton de login con Google
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get signInGoogle;

  /// Encabezado del home cuando el pasajero puede pedir un taxi
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vas?'**
  String get bookingWhereTo;

  /// Encabezado alternativo del home
  ///
  /// In es, this message translates to:
  /// **'¿Listo para viajar?'**
  String get bookingReadyToRide;

  /// Saludo hablado (TTS) al entrar al home
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a TaxiGo'**
  String get bookingWelcomeAnnouncement;

  /// Boton principal que inicia la solicitud
  ///
  /// In es, this message translates to:
  /// **'Solicitar taxi'**
  String get bookingRequestTaxi;

  /// Estado mientras se verifica el permiso de ubicacion
  ///
  /// In es, this message translates to:
  /// **'Comprobando permisos...'**
  String get bookingCheckingPermissions;

  /// Estado mientras se resuelve la ubicacion por GPS. OJO: el texto original decia 'Ubteniendo tu ubicacion...' (typo y sin acentos); se corrigio al migrar
  ///
  /// In es, this message translates to:
  /// **'Obteniendo tu ubicación...'**
  String get bookingGettingLocation;

  /// Estado mientras se geocodifica la direccion. Mismo typo corregido que bookingGettingLocation
  ///
  /// In es, this message translates to:
  /// **'Obteniendo tu dirección...'**
  String get bookingGettingAddress;

  /// Placeholder del buscador de direcciones
  ///
  /// In es, this message translates to:
  /// **'Buscar dirección o lugar...'**
  String get bookingSearchHint;

  /// Busqueda de direcciones sin resultados
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get bookingNoResults;

  /// Tooltip del boton que abre el selector de ubicacion en el mapa
  ///
  /// In es, this message translates to:
  /// **'Elegir en el mapa'**
  String get bookingPickOnMap;

  /// Titulo del dialogo de confirmacion antes de pedir el taxi
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar viaje?'**
  String get bookingConfirmTitle;

  /// Cuerpo del dialogo de confirmacion, seguido de la direccion
  ///
  /// In es, this message translates to:
  /// **'Un conductor será enviado a la siguiente ubicación:'**
  String get bookingConfirmBody;

  /// Boton que confirma la solicitud en el dialogo
  ///
  /// In es, this message translates to:
  /// **'Solicitar'**
  String get bookingRequest;

  /// Titulo de la pantalla que se muestra sin permiso de ubicacion
  ///
  /// In es, this message translates to:
  /// **'¿Dónde te encuentras?'**
  String get locationWhereAreYou;

  /// Titulo del popup de espera
  ///
  /// In es, this message translates to:
  /// **'Buscando conductor...'**
  String get waitingTitle;

  /// Cuerpo del popup de espera
  ///
  /// In es, this message translates to:
  /// **'Estamos buscando un taxi disponible para tu viaje. Por favor espera, un conductor aceptará tu solicitud en breve.'**
  String get waitingBody;

  /// Aviso cuando un conductor acepta la solicitud
  ///
  /// In es, this message translates to:
  /// **'Carrera aceptada'**
  String get waitingRideAccepted;

  /// Toast cuando la solicitud se cancela por timeout o por el backend
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo no hay conductores disponibles. Intenta de nuevo en unos minutos.'**
  String get waitingNoDrivers;

  /// Boton que cancela la solicitud mientras se busca conductor
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get waitingCancelRequest;

  /// Toast cuando falla la cancelacion automatica por timeout
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar automáticamente. Intenta cancelar de nuevo.'**
  String get waitingAutoCancelFailed;

  /// Toast cuando falla la cancelacion manual
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar la solicitud. Intenta de nuevo.'**
  String get waitingCancelFailed;

  /// Titulo del registro del pasajero
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get onboardingTitle;

  /// Subtitulo del registro del pasajero
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos quién eres para poder identificarte en tus viajes.'**
  String get onboardingSubtitle;

  /// Enlace para cerrar sesion desde el registro
  ///
  /// In es, this message translates to:
  /// **'¿No eres tú? Cerrar sesión'**
  String get onboardingSignOutPrompt;

  /// Titulo de la pantalla de edicion y boton que la abre
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEdit;

  /// Toast de exito al guardar el perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// Aviso hablado (TTS) de que el conductor cancelo
  ///
  /// In es, this message translates to:
  /// **'El conductor canceló el viaje'**
  String get rideDriverCancelledAnnouncement;

  /// Aviso hablado (TTS) y titulo del dialogo de llegada del conductor
  ///
  /// In es, this message translates to:
  /// **'El conductor ha llegado'**
  String get rideDriverArrivedAnnouncement;

  /// Agradecimiento hablado (TTS) al completarse el viaje
  ///
  /// In es, this message translates to:
  /// **'Taxi Go te agradece por elegir nuestros servicios.'**
  String get rideThanksAnnouncement;

  /// Titulo de la pantalla de seguimiento del viaje
  ///
  /// In es, this message translates to:
  /// **'Tu viaje'**
  String get rideYourTripTitle;

  /// Texto mientras no llegaron los datos del conductor asignado
  ///
  /// In es, this message translates to:
  /// **'Buscando datos del conductor...'**
  String get rideLoadingDriver;

  /// Estado del viaje mientras el conductor se acerca
  ///
  /// In es, this message translates to:
  /// **'Tu conductor está en camino'**
  String get rideDriverOnTheWay;

  /// Mostrado cuando no se conoce la direccion del punto de recogida
  ///
  /// In es, this message translates to:
  /// **'Ubicación no disponible'**
  String get rideLocationUnavailable;

  /// Boton que cancela el viaje ya aceptado
  ///
  /// In es, this message translates to:
  /// **'Cancelar viaje'**
  String get rideCancel;

  /// ETA cuando el conductor esta a menos de un minuto
  ///
  /// In es, this message translates to:
  /// **'Llegando'**
  String get rideArriving;

  /// ETA en minutos
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String rideEtaMinutes(int minutes);

  /// Distancia en metros (bajo 1 km)
  ///
  /// In es, this message translates to:
  /// **'{meters} m'**
  String rideDistanceMeters(int meters);

  /// Distancia en kilometros, con un decimal
  ///
  /// In es, this message translates to:
  /// **'{km} km'**
  String rideDistanceKilometers(String km);

  /// Titulo del dialogo de confirmacion de cancelacion
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar viaje?'**
  String get cancelRideDialogTitle;

  /// Cuerpo del dialogo de confirmacion de cancelacion
  ///
  /// In es, this message translates to:
  /// **'Tu conductor ya está en camino. Si cancelas ahora, es posible que se te aplique un cargo por cancelación.'**
  String get cancelRideDialogBody;

  /// Boton que descarta la cancelacion
  ///
  /// In es, this message translates to:
  /// **'Continuar viaje'**
  String get cancelRideContinue;

  /// Cuerpo del dialogo de llegada del conductor
  ///
  /// In es, this message translates to:
  /// **'Tu conductor te está esperando en el punto de recogida. Dirígete al vehículo.'**
  String get driverArrivedBody;

  /// Boton con el que el pasajero confirma que va hacia el auto
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get driverArrivedConfirm;

  /// Titulo del dialogo de viaje cancelado por el conductor
  ///
  /// In es, this message translates to:
  /// **'Viaje cancelado'**
  String get driverCancelledTitle;

  /// Cuerpo del dialogo de viaje cancelado por el conductor
  ///
  /// In es, this message translates to:
  /// **'Tu conductor canceló el viaje. Puedes solicitar otro taxi cuando quieras.'**
  String get driverCancelledBody;

  /// Titulo del dialogo de viaje completado
  ///
  /// In es, this message translates to:
  /// **'Has llegado a tu destino'**
  String get tripCompletedTitle;

  /// Cuerpo del dialogo de viaje completado
  ///
  /// In es, this message translates to:
  /// **'Gracias por elegirnos. Esperamos verte pronto de nuevo.'**
  String get tripCompletedBody;

  /// Titulo del indicador de distancia al conductor
  ///
  /// In es, this message translates to:
  /// **'El conductor está en camino'**
  String get distanceIndicatorTitle;

  /// Subtitulo del indicador de distancia
  ///
  /// In es, this message translates to:
  /// **'Su conductor se dirige al lugar de recogida.'**
  String get distanceIndicatorSubtitle;

  /// Extremo del indicador que representa al pasajero
  ///
  /// In es, this message translates to:
  /// **'Tu ubicación'**
  String get distanceYourLocation;

  /// Extremo del indicador que representa al conductor
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get distanceDriver;

  /// Etiqueta del dato de distancia
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get distanceLabel;

  /// Etiqueta del dato de tiempo estimado de llegada
  ///
  /// In es, this message translates to:
  /// **'Tiempo estimado'**
  String get distanceEta;

  /// Titulo de la pantalla del selector de ubicacion
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu ubicación'**
  String get mapPickerTitle;

  /// Boton que confirma la ubicacion elegida en el mapa
  ///
  /// In es, this message translates to:
  /// **'Confirmar ubicación'**
  String get mapPickerConfirm;

  /// Texto mientras se geocodifica la posicion del mapa
  ///
  /// In es, this message translates to:
  /// **'Buscando dirección...'**
  String get mapPickerSearching;

  /// Mensaje cuando falla la geocodificacion inversa
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la dirección.'**
  String get mapPickerAddressFailed;

  /// Ayuda sobre el pin central del mapa
  ///
  /// In es, this message translates to:
  /// **'Mueve el mapa para elegir tu ubicación'**
  String get mapPickerHint;

  /// Mensaje en el selector de mapa cuando el pin cae fuera de los sectores de Riobamba; el boton de confirmar queda deshabilitado
  ///
  /// In es, this message translates to:
  /// **'Fuera de la zona de cobertura'**
  String get mapPickerOutOfCoverage;

  /// Titulo de la tarjeta de ubicacion cuando el punto elegido no pertenece a ningun sector de Riobamba
  ///
  /// In es, this message translates to:
  /// **'Fuera de la zona de cobertura'**
  String get bookingOutOfCoverageTitle;

  /// Explicacion debajo del titulo de fuera de cobertura, en la pantalla de pedir taxi
  ///
  /// In es, this message translates to:
  /// **'Elige un punto dentro de Riobamba para pedir tu taxi.'**
  String get bookingOutOfCoverageMessage;

  /// Valor mostrado cuando un dato opcional del perfil esta vacio
  ///
  /// In es, this message translates to:
  /// **'No registrado'**
  String get commonNotProvided;

  /// Boton que guarda un formulario
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// Estado del boton mientras se guarda
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get commonSaving;

  /// Error de validacion del campo de nombres
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus nombres'**
  String get validationFirstName;

  /// Error de validacion del campo de apellidos
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus apellidos'**
  String get validationLastName;

  /// Boton que avanza al paso siguiente o completa el registro del pasajero
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// Mensaje de error para FailureCode.sessionVerifyFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu sesión. Intenta de nuevo.'**
  String get failureSessionVerifyFailed;

  /// Mensaje de error para FailureCode.signInFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Intenta de nuevo.'**
  String get failureSignInFailed;

  /// Mensaje de error para FailureCode.signOutFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cerrar sesión. Intenta de nuevo.'**
  String get failureSignOutFailed;

  /// Mensaje de error para FailureCode.notAuthenticated
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Inicia sesión de nuevo.'**
  String get failureNotAuthenticated;

  /// Mensaje de error para FailureCode.gpsDisabled
  ///
  /// In es, this message translates to:
  /// **'El servicio de GPS del dispositivo está desactivado.'**
  String get failureGpsDisabled;

  /// Mensaje de error para FailureCode.locationFetchFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener tu ubicación. Intenta de nuevo.'**
  String get failureLocationFetchFailed;

  /// Mensaje de error para FailureCode.addressNotFound
  ///
  /// In es, this message translates to:
  /// **'No se pudo encontrar una dirección para esta ubicación.'**
  String get failureAddressNotFound;

  /// Mensaje de error para FailureCode.locationProcessFailed
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado al procesar la ubicación.'**
  String get failureLocationProcessFailed;

  /// Mensaje de error para FailureCode.networkError
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión a internet.'**
  String get failureNetworkError;

  /// Mensaje de error para FailureCode.mapsServerError
  ///
  /// In es, this message translates to:
  /// **'No se pudo contactar al servicio de mapas. Intenta de nuevo.'**
  String get failureMapsServerError;

  /// Mensaje de error para FailureCode.placeSuggestionsFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudieron buscar lugares. Intenta de nuevo.'**
  String get failurePlaceSuggestionsFailed;

  /// Mensaje de error para FailureCode.placeDetailsFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el detalle del lugar. Intenta de nuevo.'**
  String get failurePlaceDetailsFailed;

  /// Mensaje de error para FailureCode.rideRequestFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo solicitar el taxi. Intenta de nuevo.'**
  String get failureRideRequestFailed;

  /// Mensaje de error para FailureCode.rideRequestCancelFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar la solicitud. Intenta de nuevo.'**
  String get failureRideRequestCancelFailed;

  /// Mensaje de error para FailureCode.rideRequestCancelUnavailable
  ///
  /// In es, this message translates to:
  /// **'La solicitud ya no está disponible para cancelar.'**
  String get failureRideRequestCancelUnavailable;

  /// Mensaje de error para FailureCode.rideCancelNotAllowed
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para cancelar este viaje.'**
  String get failureRideCancelNotAllowed;

  /// Mensaje de error para FailureCode.rideCancelUnavailable
  ///
  /// In es, this message translates to:
  /// **'El viaje ya no está disponible para cancelar.'**
  String get failureRideCancelUnavailable;

  /// Mensaje de error para FailureCode.rideCancelFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar el viaje. Intenta de nuevo.'**
  String get failureRideCancelFailed;

  /// Mensaje de error para FailureCode.activeTripCheckFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar si tienes un viaje en curso.'**
  String get failureActiveTripCheckFailed;

  /// Mensaje de error para FailureCode.confirmFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo confirmar. Intenta de nuevo.'**
  String get failureConfirmFailed;

  /// Mensaje de error para FailureCode.chatWriteNotAllowed
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para escribir en este viaje.'**
  String get failureChatWriteNotAllowed;

  /// Mensaje de error para FailureCode.chatRideFinished
  ///
  /// In es, this message translates to:
  /// **'El viaje ya finalizó, no se pueden enviar más mensajes.'**
  String get failureChatRideFinished;

  /// Mensaje de error para FailureCode.chatSendFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el mensaje. Intenta de nuevo.'**
  String get failureChatSendFailed;

  /// Mensaje de error para FailureCode.accountHasActiveRide
  ///
  /// In es, this message translates to:
  /// **'Tienes un viaje activo. Finalízalo o cancélalo antes de eliminar tu cuenta.'**
  String get failureAccountHasActiveRide;

  /// Mensaje de error para FailureCode.accountDeleteFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar tu cuenta. Intenta nuevamente.'**
  String get failureAccountDeleteFailed;

  /// Mensaje de error para FailureCode.passengerProfileCheckFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar tu información de pasajero'**
  String get failurePassengerProfileCheckFailed;

  /// Mensaje de error para FailureCode.profileSaveFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu información. Intenta nuevamente.'**
  String get failureProfileSaveFailed;

  /// Mensaje de error para FailureCode.profileUpdateFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar tu información. Intenta nuevamente.'**
  String get failureProfileUpdateFailed;

  /// Mensaje de error para FailureCode.imagePickFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la imagen seleccionada'**
  String get failureImagePickFailed;

  /// Mensaje de error para FailureCode.unexpected
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta de nuevo.'**
  String get failureUnexpected;

  /// Mensaje de error para FailureCode.chatMessagesLoadFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los mensajes. Intenta de nuevo.'**
  String get failureChatMessagesLoadFailed;

  /// Mensaje de error para FailureCode.profileLoadFailed
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu información'**
  String get failureProfileLoadFailed;

  /// Mensaje de error para FailureCode.locationPermissionDenied
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos de ubicación.'**
  String get failureLocationPermissionDenied;

  /// Encabezado de la seccion de idioma en ajustes, en mayusculas por estilo visual
  ///
  /// In es, this message translates to:
  /// **'IDIOMA'**
  String get settingsSectionLanguage;

  /// Opcion que sigue el idioma del dispositivo (es el default)
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsLanguageSystem;

  /// Nombre del idioma espanol. NO se traduce: por convencion cada idioma se muestra en si mismo, para que alguien que no entiende el idioma actual lo reconozca
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// Nombre del idioma ingles. NO se traduce, mismo criterio que settingsLanguageSpanish
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
