import 'package:get_it/get_it.dart';
import '../data/repository/connectivity_repository_impl.dart';
import '../domain/repository/connectivity_repository.dart';
import '../presentation/cubit/connectivity_cubit.dart';

void initConnectivityDI(GetIt sl) {
  sl.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(),
  );
  // Singleton (no factory): tanto el banner global como ChatBloc necesitan
  // conocer/reaccionar al mismo estado de conectividad durante toda la
  // sesión, no uno nuevo por pantalla.
  sl.registerLazySingleton(
    () => ConnectivityCubit(repository: sl<ConnectivityRepository>()),
  );
}
