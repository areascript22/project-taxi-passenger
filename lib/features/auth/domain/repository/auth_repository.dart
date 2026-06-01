import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';

abstract class AuthRepository{
  Future<Either<Failure, Unit >> signInWithGoogle();

  Future<Either<Failure, bool>> isUserAuthenticated();
}