import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/auth/di/auth_service_locator.dart';
import 'package:passenger_app/features/passenger_profile/di/passenger_profile_service_locator.dart';
import 'package:passenger_app/shared/feedback/di/feedback_service_locator.dart';
import 'package:passenger_app/shared/geocoding/di/geocoding_service_locator.dart';
import 'package:passenger_app/shared/geolocator/di/geolocator_service_locator.dart';
import 'package:passenger_app/shared/image_picker/di/image_picker_service_locator.dart';
import 'package:passenger_app/shared/services/dotenv/dotenv_service_locator.dart';
import 'package:passenger_app/shared/settings/di/settings_service_locator.dart';
import 'package:passenger_app/shared/vibration/di/vibration_service_locator.dart';
import 'package:passenger_app/shared/voice/di/voice_service_locator.dart';
import '../../features/booking/di/booking_locator.dart';
import '../../features/map/di/map_locator.dart';
import '../../features/ride_tracking/di/ride_tracking_service_locator.dart';
import '../../shared/di/shared_service_locator.dart';

final GetIt mainServiceLocator = GetIt.instance;

Future<void> initMainServiceLocator() async {
  initImagePickerDI(mainServiceLocator);
  initPassengerProfileDI(mainServiceLocator);
  initSharedDI(mainServiceLocator);
  initAuthDI(mainServiceLocator);
  initGeocodingDI(mainServiceLocator);
  initBooking(mainServiceLocator);
  initMap(mainServiceLocator);
  initRideTracking(mainServiceLocator);
  initDotEnvDI(mainServiceLocator);
  initGeolocator(mainServiceLocator);
  initSettingsDI(mainServiceLocator);
  initVoiceDI(mainServiceLocator);
  initVibrationDI(mainServiceLocator);
  initFeedbackDI(mainServiceLocator);
}
