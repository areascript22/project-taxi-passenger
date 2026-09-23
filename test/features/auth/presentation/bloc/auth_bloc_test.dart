import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
import 'package:passenger_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository authRepository;
  final user = UserEntity(id: 'u1', email: 'a@a.com', displayName: 'Ana');

  setUp(() {
    authRepository = _MockAuthRepository();
  });

  test('el estado inicial es AuthInitial', () {
    expect(AuthBloc(authRepository: authRepository).state, isA<AuthInitial>());
  });

  group('AuthSignInWithGoogle', () {
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando el sign-in es exitoso',
      build: () {
        when(
          () => authRepository.signInWithGoogle(),
        ).thenAnswer((_) async => Right(user));
        return AuthBloc(authRepository: authRepository);
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
      verify: (_) {
        verify(() => authRepository.signInWithGoogle()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthError] cuando el repositorio devuelve Left',
      build: () {
        when(() => authRepository.signInWithGoogle()).thenAnswer(
          (_) async => Left(Failure(message: 'Google sign-in cancelado')),
        );
        return AuthBloc(authRepository: authRepository);
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'Google sign-in cancelado',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'un segundo intento tras un error también emite loading -> resultado',
      build: () {
        var callCount = 0;
        when(() => authRepository.signInWithGoogle()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return Left(Failure(message: 'falló'));
          }
          return Right(user);
        });
        return AuthBloc(authRepository: authRepository);
      },
      act: (bloc) {
        bloc.add(AuthSignInWithGoogle());
        bloc.add(AuthSignInWithGoogle());
      },
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
