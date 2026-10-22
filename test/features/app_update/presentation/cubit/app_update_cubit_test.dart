import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/app_update/domain/entity/update_requirement_entity.dart';
import 'package:passenger_app/features/app_update/domain/repository/app_update_repository.dart';
import 'package:passenger_app/features/app_update/domain/service/store_launcher_service.dart';
import 'package:passenger_app/features/app_update/presentation/cubit/app_update_cubit.dart';

class MockAppUpdateRepository extends Mock implements AppUpdateRepository {}

class MockStoreLauncherService extends Mock implements StoreLauncherService {}

void main() {
  late MockAppUpdateRepository repository;
  late MockStoreLauncherService storeLauncher;

  const storeUrl = 'https://play.google.com/store/apps/details?id=x';

  setUp(() {
    repository = MockAppUpdateRepository();
    storeLauncher = MockStoreLauncherService();
  });

  AppUpdateCubit buildCubit() =>
      AppUpdateCubit(repository: repository, storeLauncher: storeLauncher);

  test('initial state is unknown and does not require an update', () {
    final cubit = buildCubit();

    expect(cubit.state.status, AppUpdateStatus.unknown);
    expect(cubit.state.isUpdateRequired, isFalse);
    expect(cubit.state.errorCode, isNull);
  });

  group('check', () {
    blocTest<AppUpdateCubit, AppUpdateState>(
      'emits checking then updateRequired, keeping the minimum version and store url',
      setUp: () {
        when(() => repository.checkUpdate()).thenAnswer(
          (_) async => const Right(
            UpdateRequirementEntity(
              updateRequired: true,
              minimumVersion: '1.0.5',
              storeUrl: storeUrl,
            ),
          ),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.check(),
      expect: () => [
        predicate<AppUpdateState>((s) => s.status == AppUpdateStatus.checking),
        predicate<AppUpdateState>(
          (s) =>
              s.status == AppUpdateStatus.updateRequired &&
              s.isUpdateRequired &&
              s.minimumVersion == '1.0.5' &&
              s.storeUrl == storeUrl,
        ),
      ],
      verify: (_) => verify(() => repository.checkUpdate()).called(1),
    );

    blocTest<AppUpdateCubit, AppUpdateState>(
      'emits checking then allowed when the version is supported',
      setUp: () {
        when(() => repository.checkUpdate()).thenAnswer(
          (_) async => const Right(
            UpdateRequirementEntity(
              updateRequired: false,
              minimumVersion: '1.0.4',
              storeUrl: storeUrl,
            ),
          ),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.check(),
      expect: () => [
        predicate<AppUpdateState>((s) => s.status == AppUpdateStatus.checking),
        predicate<AppUpdateState>(
          (s) => s.status == AppUpdateStatus.allowed && !s.isUpdateRequired,
        ),
      ],
    );

    // Falla ABIERTO: sin red o con el servidor caído la app sigue.
    blocTest<AppUpdateCubit, AppUpdateState>(
      'emits allowed (never updateRequired) when the check fails',
      setUp: () {
        when(() => repository.checkUpdate()).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.appUpdateCheckFailed)),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.check(),
      expect: () => [
        predicate<AppUpdateState>((s) => s.status == AppUpdateStatus.checking),
        predicate<AppUpdateState>(
          (s) => s.status == AppUpdateStatus.allowed && !s.isUpdateRequired,
        ),
      ],
    );

    blocTest<AppUpdateCubit, AppUpdateState>(
      'does nothing when a check is already in progress',
      seed: () => const AppUpdateState(status: AppUpdateStatus.checking),
      build: buildCubit,
      act: (cubit) => cubit.check(),
      expect: () => <AppUpdateState>[],
      verify: (_) => verifyNever(() => repository.checkUpdate()),
    );
  });

  group('openStore', () {
    blocTest<AppUpdateCubit, AppUpdateState>(
      'opens the store url it received from the server',
      setUp: () {
        when(() => storeLauncher.open(url: any(named: 'url'))).thenAnswer(
          (_) async => const Right(unit),
        );
      },
      build: buildCubit,
      seed: () => const AppUpdateState(
        status: AppUpdateStatus.updateRequired,
        minimumVersion: '1.0.5',
        storeUrl: storeUrl,
      ),
      act: (cubit) => cubit.openStore(),
      verify: (_) =>
          verify(() => storeLauncher.open(url: storeUrl)).called(1),
    );

    blocTest<AppUpdateCubit, AppUpdateState>(
      'emits an errorCode when the store cannot be opened',
      setUp: () {
        when(() => storeLauncher.open(url: any(named: 'url'))).thenAnswer(
          (_) async => Left(Failure(code: FailureCode.storeOpenFailed)),
        );
      },
      build: buildCubit,
      seed: () => const AppUpdateState(
        status: AppUpdateStatus.updateRequired,
        storeUrl: storeUrl,
      ),
      act: (cubit) => cubit.openStore(),
      expect: () => [
        predicate<AppUpdateState>(
          (s) => s.isUpdateRequired && s.errorCode == FailureCode.storeOpenFailed,
        ),
      ],
    );

    // Un nuevo intento limpia el error anterior mientras se reintenta.
    blocTest<AppUpdateCubit, AppUpdateState>(
      'clears the previous error before retrying',
      setUp: () {
        when(() => storeLauncher.open(url: any(named: 'url'))).thenAnswer(
          (_) async => const Right(unit),
        );
      },
      build: buildCubit,
      seed: () => const AppUpdateState(
        status: AppUpdateStatus.updateRequired,
        storeUrl: storeUrl,
        errorCode: FailureCode.storeOpenFailed,
      ),
      act: (cubit) => cubit.openStore(),
      expect: () => [
        predicate<AppUpdateState>((s) => s.errorCode == null && s.isUpdateRequired),
      ],
    );
  });
}
