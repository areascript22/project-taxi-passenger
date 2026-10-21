import 'package:get_it/get_it.dart';
import '../presentation/cubit/profile_photo_cubit.dart';

void initProfilePhotoDI(GetIt sl) {
  // Singleton (no factory): el avatar de la pantalla de pedir taxi y la pantalla
  // de edición del perfil tienen que ver la misma foto durante toda la sesión.
  sl.registerLazySingleton(() => ProfilePhotoCubit());
}
