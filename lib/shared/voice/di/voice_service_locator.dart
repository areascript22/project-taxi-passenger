import 'package:get_it/get_it.dart';
import '../service/voice_service.dart';
import '../service/voice_service_impl.dart';

void initVoiceDI(GetIt sl) {
  sl.registerLazySingleton<VoiceService>(() => VoiceServiceImpl());
}
