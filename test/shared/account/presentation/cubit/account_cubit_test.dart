import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/shared/account/domain/repository/account_repository.dart';
import 'package:passenger_app/shared/account/presentation/cubit/account_cubit.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository repository;

  setUp(() {
    repository = MockAccountRepository();
  });

  AccountCubit buildCubit() => AccountCubit(accountRepository: repository);

  test('initial state is not deleting, with no error and not deleted', () {
    final cubit = buildCubit();
    expect(cubit.state.isDeleting, isFalse);
    expect(cubit.state.errorCode, isNull);
    expect(cubit.state.wasDeleted, isFalse);
  });

  group('deleteAccount', () {
    blocTest<AccountCubit, AccountState>(
      'emits isDeleting true then wasDeleted true on success',
      setUp: () {
        when(() => repository.deleteAccount()).thenAnswer((_) async => const Right(unit));
      },
      build: buildCubit,
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        predicate<AccountState>((s) => s.isDeleting && s.errorCode == null),
        predicate<AccountState>((s) => !s.isDeleting && s.wasDeleted),
      ],
    );

    blocTest<AccountCubit, AccountState>(
      'emits isDeleting true then an errorCode on failure (e.g. active ride conflict)',
      setUp: () {
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.unexpected)),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        predicate<AccountState>((s) => s.isDeleting),
        predicate<AccountState>(
          (s) => !s.isDeleting && s.errorCode != null && !s.wasDeleted,
        ),
      ],
    );

    blocTest<AccountCubit, AccountState>(
      'clears a previous error when retried',
      setUp: () {
        when(() => repository.deleteAccount()).thenAnswer((_) async => const Right(unit));
      },
      build: buildCubit,
      seed: () => const AccountState(errorCode: FailureCode.unexpected),
      act: (cubit) => cubit.deleteAccount(),
      expect: () => [
        predicate<AccountState>((s) => s.isDeleting && s.errorCode == null),
        predicate<AccountState>((s) => !s.isDeleting && s.wasDeleted),
      ],
    );

    // El borrado puede tardar decenas de segundos y la pantalla de Settings
    // puede desmontarse mientras tanto (BlocProvider cierra el cubit). Sin el
    // guard de isClosed, el emit lanzaría StateError y se perdería como error
    // async no manejado, porque la UI llama deleteAccount() sin await.
    test('does not throw when it resolves after the cubit was closed', () async {
      final completer = Completer<Either<Failure, Unit>>();
      when(() => repository.deleteAccount()).thenAnswer((_) => completer.future);

      final cubit = buildCubit();
      final pending = cubit.deleteAccount();
      await cubit.close();
      completer.complete(Left(Failure(code: FailureCode.unexpected)));

      await expectLater(pending, completes);
    });
  });
}
