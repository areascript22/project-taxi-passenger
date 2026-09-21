import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/chat_presence/service/chat_presence_tracker.dart';

void main() {
  group('ChatPresenceTracker', () {
    test('empieza sin ningún chat abierto', () {
      final tracker = ChatPresenceTracker();

      expect(tracker.openRideId.value, isNull);
      expect(tracker.isOpen(rideId: 'ride_1'), isFalse);
    });

    test('markOpen marca ese rideId como el chat abierto', () {
      final tracker = ChatPresenceTracker();

      tracker.markOpen(rideId: 'ride_1');

      expect(tracker.openRideId.value, 'ride_1');
      expect(tracker.isOpen(rideId: 'ride_1'), isTrue);
      expect(tracker.isOpen(rideId: 'ride_2'), isFalse);
    });

    test('markClosed limpia el rideId cuando coincide con el que está abierto', () {
      final tracker = ChatPresenceTracker();
      tracker.markOpen(rideId: 'ride_1');

      tracker.markClosed(rideId: 'ride_1');

      expect(tracker.openRideId.value, isNull);
      expect(tracker.isOpen(rideId: 'ride_1'), isFalse);
    });

    test(
      'markClosed con un rideId distinto al abierto no lo pisa '
      '(navegación rápida: se cerró la pantalla de un chat viejo después '
      'de que ya se abrió una nueva)',
      () {
        final tracker = ChatPresenceTracker();
        tracker.markOpen(rideId: 'ride_1');
        tracker.markOpen(rideId: 'ride_2');

        tracker.markClosed(rideId: 'ride_1');

        expect(tracker.openRideId.value, 'ride_2');
        expect(tracker.isOpen(rideId: 'ride_2'), isTrue);
      },
    );

    test('markClosed sin ningún chat abierto no rompe nada', () {
      final tracker = ChatPresenceTracker();

      tracker.markClosed(rideId: 'ride_1');

      expect(tracker.openRideId.value, isNull);
    });
  });
}
