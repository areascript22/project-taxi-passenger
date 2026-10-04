// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taxi project';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsSectionNotifications => 'NOTIFICATIONS';

  @override
  String get settingsVoiceTitle => 'Voice';

  @override
  String get settingsVoiceSubtitle => 'Spoken announcements';

  @override
  String get settingsVibrationTitle => 'Vibration';

  @override
  String get settingsVibrationSubtitle => 'Vibrate on important events';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'This action cannot be undone';

  @override
  String get deleteAccountDialogBody => 'This action is irreversible. Your profile, your photo and your chats will be deleted. You will not be able to recover this information.\n\nAre you sure you want to delete your account?';

  @override
  String get deleteAccountSuccess => 'Account deleted successfully';

  @override
  String bookingCancelCountdown(String time) {
    return 'We\'ll cancel in $time';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailShort => 'Email';

  @override
  String get commonUnderstood => 'Got it';

  @override
  String get commonPickupPoint => 'Pickup point';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get logoutDialogBody => 'Are you sure you want to sign out?';

  @override
  String get navRequest => 'Book';

  @override
  String get navProfile => 'Profile';

  @override
  String get photoSheetTitle => 'Profile photo';

  @override
  String get photoTakePhoto => 'Take a photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get chatTitle => 'Chat with your driver';

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatInputHint => 'Write a message...';

  @override
  String get sessionCheckFailed => 'We could not verify your session. Check your connection and try again.';

  @override
  String get signInWelcome => 'Welcome, passenger';

  @override
  String get signInTagline => 'Travel safely and quickly with us.';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get bookingWhereTo => 'Where are you going?';

  @override
  String get bookingReadyToRide => 'Ready to ride?';

  @override
  String get bookingWelcomeAnnouncement => 'Welcome to TaxiGo';

  @override
  String get bookingRequestTaxi => 'Request a taxi';

  @override
  String get bookingCheckingPermissions => 'Checking permissions...';

  @override
  String get bookingGettingLocation => 'Getting your location...';

  @override
  String get bookingGettingAddress => 'Getting your address...';

  @override
  String get bookingSearchHint => 'Search for an address or place...';

  @override
  String get bookingNoResults => 'No results found';

  @override
  String get bookingPickOnMap => 'Pick on the map';

  @override
  String get bookingConfirmTitle => 'Confirm the ride?';

  @override
  String get bookingConfirmBody => 'A driver will be sent to the following location:';

  @override
  String get bookingRequest => 'Request';

  @override
  String get locationWhereAreYou => 'Where are you?';

  @override
  String get waitingTitle => 'Looking for a driver...';

  @override
  String get waitingBody => 'We are looking for an available taxi for your ride. Please wait, a driver will accept your request shortly.';

  @override
  String get waitingRideAccepted => 'Ride accepted';

  @override
  String get waitingNoDrivers => 'There are no drivers available right now. Try again in a few minutes.';

  @override
  String get waitingCancelRequest => 'Cancel request';

  @override
  String get waitingAutoCancelFailed => 'We could not cancel automatically. Try cancelling again.';

  @override
  String get waitingCancelFailed => 'The request could not be cancelled. Try again.';

  @override
  String get onboardingTitle => 'Complete your profile';

  @override
  String get onboardingSubtitle => 'Tell us who you are so we can identify you on your rides.';

  @override
  String get onboardingSignOutPrompt => 'Not you? Sign out';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get rideDriverCancelledAnnouncement => 'The driver cancelled the ride';

  @override
  String get rideDriverArrivedAnnouncement => 'The driver has arrived';

  @override
  String get rideThanksAnnouncement => 'TaxiGo thanks you for choosing our services.';

  @override
  String get rideYourTripTitle => 'Your ride';

  @override
  String get rideLoadingDriver => 'Loading driver details...';

  @override
  String get rideDriverOnTheWay => 'Your driver is on the way';

  @override
  String get rideLocationUnavailable => 'Location unavailable';

  @override
  String get rideCancel => 'Cancel ride';

  @override
  String get rideArriving => 'Arriving';

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
  String get cancelRideDialogTitle => 'Cancel the ride?';

  @override
  String get cancelRideDialogBody => 'Your driver is already on the way. If you cancel now, a cancellation fee may apply.';

  @override
  String get cancelRideContinue => 'Keep the ride';

  @override
  String get driverArrivedBody => 'Your driver is waiting for you at the pickup point. Head to the vehicle.';

  @override
  String get driverArrivedConfirm => 'On my way';

  @override
  String get driverCancelledTitle => 'Ride cancelled';

  @override
  String get driverCancelledBody => 'Your driver cancelled the ride. You can request another taxi whenever you want.';

  @override
  String get tripCompletedTitle => 'You have arrived at your destination';

  @override
  String get tripCompletedBody => 'Thanks for choosing us. We hope to see you again soon.';

  @override
  String get distanceIndicatorTitle => 'The driver is on the way';

  @override
  String get distanceIndicatorSubtitle => 'Your driver is heading to the pickup point.';

  @override
  String get distanceYourLocation => 'Your location';

  @override
  String get distanceDriver => 'Driver';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get distanceEta => 'Estimated time';

  @override
  String get mapPickerTitle => 'Select your location';

  @override
  String get mapPickerConfirm => 'Confirm location';

  @override
  String get mapPickerSearching => 'Looking up the address...';

  @override
  String get mapPickerAddressFailed => 'The address could not be found.';

  @override
  String get mapPickerHint => 'Move the map to pick your location';

  @override
  String get commonNotProvided => 'Not provided';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get validationFirstName => 'Enter your first name';

  @override
  String get validationLastName => 'Enter your last name';

  @override
  String get commonContinue => 'Continue';

  @override
  String get failureSessionVerifyFailed => 'We could not verify your session. Try again.';

  @override
  String get failureSignInFailed => 'Sign-in failed. Try again.';

  @override
  String get failureSignOutFailed => 'Sign-out failed. Try again.';

  @override
  String get failureNotAuthenticated => 'Your session expired. Sign in again.';

  @override
  String get failureGpsDisabled => 'Your device\'s GPS service is turned off.';

  @override
  String get failureLocationFetchFailed => 'Your location could not be obtained. Try again.';

  @override
  String get failureAddressNotFound => 'No address could be found for this location.';

  @override
  String get failureLocationProcessFailed => 'Something went wrong while processing the location.';

  @override
  String get failureNetworkError => 'Check your internet connection.';

  @override
  String get failureMapsServerError => 'The map service could not be reached. Try again.';

  @override
  String get failurePlaceSuggestionsFailed => 'Places could not be searched. Try again.';

  @override
  String get failurePlaceDetailsFailed => 'The place details could not be loaded. Try again.';

  @override
  String get failureRideRequestFailed => 'The taxi could not be requested. Try again.';

  @override
  String get failureRideRequestCancelFailed => 'The request could not be cancelled. Try again.';

  @override
  String get failureRideRequestCancelUnavailable => 'The request is no longer available to cancel.';

  @override
  String get failureRideCancelNotAllowed => 'You do not have permission to cancel this ride.';

  @override
  String get failureRideCancelUnavailable => 'The ride is no longer available to cancel.';

  @override
  String get failureRideCancelFailed => 'The ride could not be cancelled. Try again.';

  @override
  String get failureActiveTripCheckFailed => 'We could not check whether you have a ride in progress.';

  @override
  String get failureConfirmFailed => 'It could not be confirmed. Try again.';

  @override
  String get failureChatWriteNotAllowed => 'You do not have permission to write in this ride.';

  @override
  String get failureChatRideFinished => 'The ride already ended, no more messages can be sent.';

  @override
  String get failureChatSendFailed => 'The message could not be sent. Try again.';

  @override
  String get failureAccountHasActiveRide => 'You have an active ride. Finish or cancel it before deleting your account.';

  @override
  String get failureAccountDeleteFailed => 'Your account could not be deleted. Try again.';

  @override
  String get failurePassengerProfileCheckFailed => 'We could not verify your passenger information';

  @override
  String get failureProfileSaveFailed => 'Your information could not be saved. Try again.';

  @override
  String get failureProfileUpdateFailed => 'Your information could not be updated. Try again.';

  @override
  String get failureImagePickFailed => 'The selected image could not be loaded';

  @override
  String get failureUnexpected => 'Something went wrong. Try again.';

  @override
  String get failureChatMessagesLoadFailed => 'The messages could not be loaded. Try again.';

  @override
  String get failureProfileLoadFailed => 'Your information could not be loaded';

  @override
  String get failureLocationPermissionDenied => 'Location permission is not granted.';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageEnglish => 'English';
}
