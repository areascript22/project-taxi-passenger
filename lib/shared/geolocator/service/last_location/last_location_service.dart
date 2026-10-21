import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../../../domain/entity/user_location.dart';

/// Ultima ubicacion real del usuario, guardada en el telefono.
///
/// Sirve para abrir el mapa al instante donde el usuario estaba la ultima vez
/// en vez de esperar un fix de GPS cada vez que entra.
abstract class LastLocationService {
  /// `Right(null)` si todavia no hay ninguna guardada.
  Future<Either<Failure, UserLocation?>> getLastLocation();

  Future<Either<Failure, Unit>> saveLastLocation({
    required UserLocation location,
  });
}
