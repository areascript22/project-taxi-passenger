import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/auth/data/repository/auth_repository_impl.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late _MockFirebaseAuth auth;
  late _MockGoogleSignIn googleSignIn;
  late AuthRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_FakeAuthCredential()));

  setUp(() {
    auth = _MockFirebaseAuth();
    googleSignIn = _MockGoogleSignIn();
    repository = AuthRepositoryImpl(auth: auth, googleSignIn: googleSignIn);
    when(() => googleSignIn.initialize()).thenAnswer((_) async {});
  });

  void stubGoogleAccount() {
    final account = _MockGoogleAccount();
    final authentication = _MockGoogleAuthentication();
    when(() => authentication.idToken).thenReturn('id-token');
    when(() => account.authentication).thenReturn(authentication);
    when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);
  }

  test('devuelve Right(UserEntity) cuando Google y Firebase responden', () async {
    stubGoogleAccount();
    final user = _MockUser();
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('a@b.com');
    when(() => user.displayName).thenReturn('Ana');
    when(() => user.photoURL).thenReturn(null);
    final credential = _MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);

    final result = await repository.signInWithGoogle();

    final entity = result.getOrElse(() => throw StateError('esperaba Right'));
    expect(entity.id, 'uid-1');
    expect(entity.email, 'a@b.com');
    verify(() => googleSignIn.initialize()).called(1);
    verify(() => auth.signInWithCredential(any())).called(1);
  });

  test('devuelve signInFailed con detalle cuando Firebase devuelve user nulo',
      () async {
    stubGoogleAccount();
    final credential = _MockUserCredential();
    when(() => credential.user).thenReturn(null);
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);

    final result = await repository.signInWithGoogle();

    result.fold(
      (failure) {
        expect(failure.code, FailureCode.signInFailed);
        expect(failure.detail, 'user null');
      },
      (_) => fail('esperaba Left'),
    );
  });

  test('devuelve signInFailed con el detalle de la excepcion de Google',
      () async {
    when(() => googleSignIn.authenticate()).thenThrow(Exception('boom'));

    final result = await repository.signInWithGoogle();

    result.fold(
      (failure) {
        expect(failure.code, FailureCode.signInFailed);
        expect(failure.detail, contains('boom'));
      },
      (_) => fail('esperaba Left'),
    );
    verifyNever(() => auth.signInWithCredential(any()));
  });

  test('devuelve signInFailed cuando Firebase rechaza la credencial', () async {
    stubGoogleAccount();
    when(() => auth.signInWithCredential(any())).thenThrow(
      FirebaseAuthException(code: 'invalid-credential'),
    );

    final result = await repository.signInWithGoogle();

    result.fold(
      (failure) {
        expect(failure.code, FailureCode.signInFailed);
        expect(failure.detail, contains('invalid-credential'));
      },
      (_) => fail('esperaba Left'),
    );
  });
}
