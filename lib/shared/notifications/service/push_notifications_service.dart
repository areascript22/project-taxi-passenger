import 'package:dartz/dartz.dart';
import '../../../core/error/errors.dart';

abstract class PushNotificationsService {
  // Pide permiso de notificaciones, prepara el canal de Android para poder
  // mostrar notificaciones locales en foreground, y engancha los listeners
  // de tap (foreground/background/terminated) para navegar según la ruta
  // del payload.
  Future<Either<Failure, Unit>> initialize();

  Future<Either<Failure, String?>> getToken();

  Stream<String> get onTokenRefresh;
}
