import 'package:get_it/get_it.dart';
import '../service/vibration_service.dart';
import '../service/vibration_service_impl.dart';

void initVibrationDI(GetIt sl) {
  sl.registerLazySingleton<VibrationService>(() => VibrationServiceImpl());
}
