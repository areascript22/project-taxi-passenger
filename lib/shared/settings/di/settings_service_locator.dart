import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import '../data/repository/settings_repository_impl.dart';
import '../domain/repository/settings_repository.dart';
import '../presentation/bloc/settings_bloc.dart';

void initSettingsDI(GetIt sl) {
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  // Singleton (no factory): MyApp lo provee una sola vez en la raíz para
  // controlar el ThemeMode de MaterialApp.router, y SettingsScreen debe
  // leer/mutar esa MISMA instancia.
  sl.registerLazySingleton(
    () => SettingsBloc(
      repository: sl<SettingsRepository>(),
      profileRepository: sl<PassengerProfileRepository>(),
      sessionRepository: sl<SessionRepository>(),
    ),
  );
}
