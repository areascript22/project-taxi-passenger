import 'package:get_it/get_it.dart';
import '../../settings/domain/repository/settings_repository.dart';
import '../../vibration/service/vibration_service.dart';
import '../../voice/service/voice_service.dart';
import '../feedback_service.dart';
import '../feedback_service_impl.dart';

void initFeedbackDI(GetIt sl) {
  sl.registerLazySingleton<FeedbackService>(
    () => FeedbackServiceImpl(
      settingsRepository: sl<SettingsRepository>(),
      voiceService: sl<VoiceService>(),
      vibrationService: sl<VibrationService>(),
    ),
  );
}
