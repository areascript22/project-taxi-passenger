import 'package:passenger_app/shared/chat_presence/service/pending_chat_navigation_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingChatNavigationTracker', () {
    test('empieza sin ningún pedido pendiente', () {
      final tracker = PendingChatNavigationTracker();

      expect(tracker.pendingRideId.value, isNull);
      expect(tracker.consumeIfMatches(rideId: 'ride_1'), isFalse);
    });

    test('request deja el rideId pendiente', () {
      final tracker = PendingChatNavigationTracker();

      tracker.request(rideId: 'ride_1');

      expect(tracker.pendingRideId.value, 'ride_1');
    });

    test('consumeIfMatches devuelve true y limpia el pendiente cuando coincide', () {
      final tracker = PendingChatNavigationTracker();
      tracker.request(rideId: 'ride_1');

      final consumed = tracker.consumeIfMatches(rideId: 'ride_1');

      expect(consumed, isTrue);
      expect(tracker.pendingRideId.value, isNull);
    });

    test(
      'consumeIfMatches con un rideId distinto no consume el pendiente '
      '(evita abrir el chat equivocado)',
      () {
        final tracker = PendingChatNavigationTracker();
        tracker.request(rideId: 'ride_1');

        final consumed = tracker.consumeIfMatches(rideId: 'ride_2');

        expect(consumed, isFalse);
        expect(tracker.pendingRideId.value, 'ride_1');
      },
    );
  });
}
