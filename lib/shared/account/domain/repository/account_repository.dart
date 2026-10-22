import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

abstract class AccountRepository {
  // Sin parámetros: el uid del usuario a eliminar sale del Bearer token que
  // DioClient ya adjunta a cada request (ver AccountController en el
  // backend), nunca del cliente.
  Future<Either<Failure, Unit>> deleteAccount();
}
