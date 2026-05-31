import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;

      // 1. CORRECCIÓN: Se utiliza el Singleton en lugar del constructor
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // OBLIGATORIO EN v7+: Debes inicializar el SDK antes de cualquier acción
      await googleSignIn.initialize();

      // 2. CORRECCIÓN: Se utiliza authenticate() en lugar de signIn()
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        // 3. CORRECCIÓN: Se retorna el Either (left) en vez de un 'null' plano
        return left(Failure(message: "El usuario canceló el flujo de selección de cuenta"));
      }

      // Obtener los detalles de autenticación de la cuenta seleccionada
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. CORRECCIÓN: Firebase funciona perfectamente solo con el idToken.
      // Se elimina el accessToken que ya no existe en este paso en la v7+.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con la credencial generada
      await auth.signInWithCredential(credential);

      // 5. CORRECCIÓN: Se pasa la constante 'unit' para cumplir con la firma del método
      return right(unit);

    } catch (e) {
      print("Error en Google Sign-In: $e");
      return left(Failure(message: "Error interno en Google Sign-In: $e"));
    }
  }
}