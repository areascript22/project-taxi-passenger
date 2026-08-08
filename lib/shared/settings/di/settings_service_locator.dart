import 'package:get_it/get_it.dart';
import '../data/repository/settings_repository_impl.dart';
import '../domain/repository/settings_repository.dart';
import '../presentation/bloc/settings_bloc.dart';

void initSettingsDI(GetIt sl) {
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  sl.registerFactory(() => SettingsBloc(repository: sl<SettingsRepository>()));
}
