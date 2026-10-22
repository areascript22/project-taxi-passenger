import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/shared/connectivity/domain/repository/connectivity_repository.dart';
import 'package:passenger_app/shared/connectivity/presentation/cubit/connectivity_cubit.dart';

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

void main() {
  late MockConnectivityRepository repository;
  late StreamController<bool> controller;

  setUp(() {
    repository = MockConnectivityRepository();
    controller = StreamController<bool>.broadcast();
    when(
      () => repository.watchConnection(),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() {
    controller.close();
  });

  test('initial status is unknown before the first reading arrives', () {
    final cubit = ConnectivityCubit(repository: repository);
    expect(cubit.state.status, ConnectivityStatus.unknown);
    expect(cubit.state.isOffline, isFalse);
  });

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits online when the repository reports a real connection',
    build: () => ConnectivityCubit(repository: repository),
    act: (_) => controller.add(true),
    expect: () => [
      predicate<ConnectivityState>(
        (s) => s.status == ConnectivityStatus.online && !s.isOffline,
      ),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits offline when the repository reports no connection',
    build: () => ConnectivityCubit(repository: repository),
    act: (_) => controller.add(false),
    expect: () => [
      predicate<ConnectivityState>(
        (s) => s.status == ConnectivityStatus.offline && s.isOffline,
      ),
    ],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'falls back to offline (conservative) when the connection stream itself '
    'errors out',
    build: () => ConnectivityCubit(repository: repository),
    act: (_) => controller.addError(Exception('boom')),
    expect: () => [
      predicate<ConnectivityState>((s) => s.status == ConnectivityStatus.offline),
    ],
  );

  test(
    'falls back to offline when subscribing to watchConnection throws '
    'synchronously',
    () {
      when(() => repository.watchConnection()).thenThrow(Exception('boom'));

      final cubit = ConnectivityCubit(repository: repository);

      expect(cubit.state.status, ConnectivityStatus.offline);
    },
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'transitions back to online after a previous offline reading',
    build: () => ConnectivityCubit(repository: repository),
    act: (_) async {
      controller.add(false);
      await Future.delayed(Duration.zero);
      controller.add(true);
    },
    expect: () => [
      predicate<ConnectivityState>((s) => s.status == ConnectivityStatus.offline),
      predicate<ConnectivityState>((s) => s.status == ConnectivityStatus.online),
    ],
  );
}
