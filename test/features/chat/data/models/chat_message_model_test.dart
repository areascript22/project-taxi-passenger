import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/features/chat/data/models/chat_message_model.dart';

void main() {
  group('ChatMessageModel.fromMap', () {
    test('parsea todos los campos desde el map de Firestore', () {
      final createdAt = DateTime(2026, 9, 17, 10, 30);

      final model = ChatMessageModel.fromMap(
        id: 'msg_1',
        rideId: 'ride_1',
        map: {
          'senderId': 'driver_uid',
          'senderRole': 'driver',
          'text': 'Ya llegué',
          'createdAt': Timestamp.fromDate(createdAt),
        },
      );

      expect(model.id, 'msg_1');
      expect(model.rideId, 'ride_1');
      expect(model.senderId, 'driver_uid');
      expect(model.senderRole, 'driver');
      expect(model.text, 'Ya llegué');
      expect(model.createdAt, createdAt);
    });

    test('usa strings vacíos como fallback para campos faltantes', () {
      final model = ChatMessageModel.fromMap(
        id: 'msg_1',
        rideId: 'ride_1',
        map: const {},
      );

      expect(model.senderId, '');
      expect(model.senderRole, '');
      expect(model.text, '');
    });

    test('toEntity mapea todos los campos a ChatMessageEntity', () {
      final createdAt = DateTime(2026, 9, 17, 10, 30);

      final entity = ChatMessageModel.fromMap(
        id: 'msg_1',
        rideId: 'ride_1',
        map: {
          'senderId': 'passenger_uid',
          'senderRole': 'passenger',
          'text': 'Ya salgo',
          'createdAt': Timestamp.fromDate(createdAt),
        },
      ).toEntity();

      expect(entity.id, 'msg_1');
      expect(entity.rideId, 'ride_1');
      expect(entity.senderId, 'passenger_uid');
      expect(entity.senderRole, 'passenger');
      expect(entity.text, 'Ya salgo');
      expect(entity.createdAt, createdAt);
    });
  });
}
