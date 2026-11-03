import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
import '../../../../shared/domain/entity/user_entity.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final FirebaseAuth auth = _auth ?? FirebaseAuth.instance;
      final GoogleSignIn googleSignIn = _googleSignIn ?? GoogleSignIn.instance;

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
        debugPrint('AuthDebug | signInWithGoogle: Firebase devolvio user nulo');
        return left(
          Failure(code: FailureCode.signInFailed, detail: 'user null'),
        );
      }
    } catch (e) {
      debugPrint('AuthDebug | Error en signInWithGoogle: $e');
      return left(Failure(code: FailureCode.signInFailed, detail: '$e'));
    }
  }
}
