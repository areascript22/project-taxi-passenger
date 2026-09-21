class ChatMessageEntity {
  ChatMessageEntity({
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
}
