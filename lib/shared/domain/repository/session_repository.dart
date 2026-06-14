import 'package:dartz/dartz.dart';
import '../../../core/error/errors.dart';
import '../entity/user_entity.dart';

abstract class SessionRepository{
  Future<Either<Failure, UserEntity>> isUserAuthenticated();
  Future<Either<Failure, Unit>> signOut();
}