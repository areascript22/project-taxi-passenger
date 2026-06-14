import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
import '../../../../shared/domain/entity/user_entity.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredentials = await auth.signInWithCredential(credential);
      final user = userCredentials.user;

      if (user != null) {
        return right(
          UserEntity(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          ),
        );
      } else {
        return left(
          Failure(
            message: "Error al obtener los datos del usuario de Firebase",
          ),
        );
      }
    } catch (e) {
      return left(Failure(message: "Error interno en Google Sign-In: $e"));
    }
  }
}
