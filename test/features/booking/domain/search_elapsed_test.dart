import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/features/booking/domain/search_elapsed.dart';

void main() {
  final openedAt = DateTime.utc(2026, 10, 11, 12, 0, 0);

  group('searchElapsed', () {
    test('a new request counts from when the popup opened', () {
      final elapsed = searchElapsed(
        now: openedAt.add(const Duration(seconds: 7)),
        openedAt: openedAt,
      );

      expect(elapsed, const Duration(seconds: 7));
    });

    test('starts at zero', () {
      expect(searchElapsed(now: openedAt, openedAt: openedAt), Duration.zero);
    });

    // La app se cerro y se reabrio: el pasajero lleva esperando desde que el
    // servidor creo la solicitud, no desde que se reabrio el popup.
    test('a resumed request counts from the server creation time', () {
      final createdAt = openedAt.subtract(const Duration(seconds: 20));

      final elapsed = searchElapsed(
        now: openedAt.add(const Duration(seconds: 3)),
        openedAt: openedAt,
        rideCreatedAtMillis: createdAt.millisecondsSinceEpoch,
      );

      expect(elapsed, const Duration(seconds: 23));
    });

    // Un reloj de telefono atrasado respecto al servidor no puede mostrar
    // tiempo negativo.
    test('never goes negative when the phone clock is behind the server', () {
      final createdAtInTheFuture = openedAt.add(const Duration(seconds: 40));

      final elapsed = searchElapsed(
        now: openedAt,
        openedAt: openedAt,
        rideCreatedAtMillis: createdAtInTheFuture.millisecondsSinceEpoch,
      );

      expect(elapsed, Duration.zero);
    });

    // Lo que el cliente ya no hace: no hay un limite del lado de la app.
    test('has no ceiling: a long search keeps counting', () {
      final elapsed = searchElapsed(
        now: openedAt.add(const Duration(minutes: 5)),
        openedAt: openedAt,
      );

      expect(elapsed, const Duration(minutes: 5));
    });
  });

  group('formatSearchElapsed', () {
    test('formats as m:ss with zero padding', () {
      expect(formatSearchElapsed(Duration.zero), '0:00');
      expect(formatSearchElapsed(const Duration(seconds: 7)), '0:07');
      expect(formatSearchElapsed(const Duration(seconds: 63)), '1:03');
      expect(formatSearchElapsed(const Duration(minutes: 12, seconds: 5)), '12:05');
    });

    test('is capped at one hour', () {
      expect(formatSearchElapsed(const Duration(hours: 3)), '59:59');
    });
  });
}
