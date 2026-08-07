import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import '../settings/domain/repository/settings_repository.dart';
import '../vibration/service/vibration_service.dart';
import '../voice/service/voice_service.dart';
import 'feedback_service.dart';

class FeedbackServiceImpl implements FeedbackService {
  final SettingsRepository settingsRepository;
  final VoiceService voiceService;
  final VibrationService vibrationService;

  FeedbackServiceImpl({
    required this.settingsRepository,
    required this.voiceService,
    required this.vibrationService,
  });

  @override
  Future<Either<Failure, Unit>> announce(
    String message, {
    bool withVibration = false,
  }) async {
    try {
      final voiceEnabledResult = await settingsRepository.isVoiceEnabled();
      final voiceEnabled = voiceEnabledResult.fold((_) => true, (v) => v);
      if (voiceEnabled) {
        await voiceService.speak(message);
      }

      if (withVibration) {
        final vibrationEnabledResult =
            await settingsRepository.isVibrationEnabled();
        final vibrationEnabled = vibrationEnabledResult.fold(
          (_) => true,
          (v) => v,
        );
        if (vibrationEnabled) {
          await vibrationService.vibrate();
        }
      }

      return const Right(unit);
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
