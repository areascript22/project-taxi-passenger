import 'package:get_it/get_it.dart';
import '../data/repository/settings_repository_impl.dart';
import '../domain/repository/settings_repository.dart';
import '../presentation/bloc/settings_bloc.dart';

void initSettingsDI(GetIt sl) {
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  // Singleton (no factory): MyApp lo provee una sola vez en la raíz para
  // controlar el ThemeMode de MaterialApp.router, y SettingsScreen debe
  // leer/mutar esa MISMA instancia.
  sl.registerLazySingleton(() => SettingsBloc(repository: sl<SettingsRepository>()));
}
