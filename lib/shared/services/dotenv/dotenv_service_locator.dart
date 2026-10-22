import 'package:get_it/get_it.dart';
import 'dotenv_service.dart';
import 'dotenv_service_impl.dart';

void initDotEnvDI(GetIt sl) {
  sl.registerLazySingleton<DotEnvService>(() => DotEnvServiceImpl());
}