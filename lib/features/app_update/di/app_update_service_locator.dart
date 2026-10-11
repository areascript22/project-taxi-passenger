import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:passenger_app/features/app_update/data/repository/app_update_repository_impl.dart';
import 'package:passenger_app/features/app_update/data/service/store_launcher_service_impl.dart';
import 'package:passenger_app/features/app_update/domain/repository/app_update_repository.dart';
import 'package:passenger_app/features/app_update/domain/service/store_launcher_service.dart';
import 'package:passenger_app/features/app_update/presentation/cubit/app_update_cubit.dart';

void initAppUpdateDI(GetIt sl) {
  sl.registerLazySingleton<AppUpdateRepository>(
    () => AppUpdateRepositoryImpl(
      appId: 'passenger',
      readVersion: () async => (await PackageInfo.fromPlatform()).version,
    ),
  );
  sl.registerLazySingleton<StoreLauncherService>(
    () => StoreLauncherServiceImpl(),
  );
  // Singleton (no factory): la pantalla de "actualiza" cubre toda la app y
  // tiene que compartir el mismo estado en cualquier ruta.
  sl.registerLazySingleton(
    () => AppUpdateCubit(
      repository: sl<AppUpdateRepository>(),
      storeLauncher: sl<StoreLauncherService>(),
    ),
  );
}
