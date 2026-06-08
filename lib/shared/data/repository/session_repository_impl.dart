import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  @override
  Future<Either<Failure, UserEntity>> isUserAuthenticated() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;

      if (currentUser != null) {
        return right(
          UserEntity(
            id: currentUser.uid,
            email: currentUser.email,
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoURL,
          ),
        );
      }

      return Left(Failure(message: 'User is not signed in'));
    } catch (e) {
      return left(Failure(message: "Error interno al verificar la sesión: $e"));
    }
  }
}
