import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/chat_message_entity.dart';

class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String rideId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  // Recibe el id del doc y el rideId (el id del doc padre) por separado en
  // vez de un QueryDocumentSnapshot completo: así queda como función pura
  // (sin depender de una conexión real a Firestore) y se puede testear sin
  // mocks del SDK -- Timestamp sí se puede instanciar en memoria.
  factory ChatMessageModel.fromMap({
    required String id,
    required String rideId,
    required Map<String, dynamic> map,
  }) {
    return ChatMessageModel(
      id: id,
      rideId: rideId,
      senderId: map['senderId'] as String? ?? '',
      senderRole: map['senderRole'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      rideId: rideId,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      createdAt: createdAt,
    );
  }
}
