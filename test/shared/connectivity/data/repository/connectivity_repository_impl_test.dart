import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/shared/connectivity/data/repository/connectivity_repository_impl.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changesController;

  setUp(() {
    connectivity = MockConnectivity();
    changesController = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => changesController.stream);
  });

  tearDown(() {
    changesController.close();
  });

  ConnectivityRepositoryImpl buildRepository({
    required Future<bool> Function() hasInternetAccessOverride,
  }) {
    return ConnectivityRepositoryImpl(
      connectivity: connectivity,
      hasInternetAccessOverride: hasInternetAccessOverride,
    );
  }

  test(
    'emits false right away when there is no active network interface, '
    'without even checking real internet access',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      var probeCalls = 0;
      final repository = buildRepository(
        hasInternetAccessOverride: () async {
          probeCalls++;
          return true;
        },
      );

      final first = await repository.watchConnection().first;

      expect(first, isFalse);
      expect(probeCalls, 0);
    },
  );

  test(
    'emits true when there is an active interface AND real internet access',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final repository = buildRepository(
        hasInternetAccessOverride: () async => true,
      );

      final first = await repository.watchConnection().first;

      expect(first, isTrue);
    },
  );

  test(
    'emits false when connected to a network interface but without real '
    'internet access (ex. portal cautivo o router sin salida)',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final repository = buildRepository(
        hasInternetAccessOverride: () async => false,
      );

      final first = await repository.watchConnection().first;

      expect(first, isFalse);
    },
  );

  test(
    'emits false instead of throwing when checkConnectivity itself fails',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenThrow(Exception('platform error'));
      final repository = buildRepository(
        hasInternetAccessOverride: () async => true,
      );

      final first = await repository.watchConnection().first;

      expect(first, isFalse);
    },
  );

  test(
    'forwards connectivity changes resolved through the same real-access '
    'check',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      final repository = buildRepository(
        hasInternetAccessOverride: () async => true,
      );

      final emissions = <bool>[];
      final subscription = repository.watchConnection().listen(
        emissions.add,
      );
      await Future.delayed(Duration.zero);

      changesController.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero);

      expect(emissions, [true, false]);
      await subscription.cancel();
    },
  );

  test(
    'collapses consecutive identical statuses from onConnectivityChanged '
    'via distinct()',
    () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      final repository = buildRepository(
        hasInternetAccessOverride: () async => true,
      );

      final emissions = <bool>[];
      final subscription = repository.watchConnection().listen(
        emissions.add,
      );
      await Future.delayed(Duration.zero);

      changesController.add([ConnectivityResult.wifi]);
      await Future.delayed(Duration.zero);
      changesController.add([ConnectivityResult.mobile]);
      await Future.delayed(Duration.zero);

      // Ambos cambios resuelven a `true` (misma cobertura wifi/mobile con
      // acceso real) -- distinct() debe colapsarlos en una sola emisión.
      expect(emissions, [false, true]);
      await subscription.cancel();
    },
  );
}
