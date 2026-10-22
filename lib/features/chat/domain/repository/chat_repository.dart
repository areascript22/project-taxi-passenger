import 'package:dartz/dartz.dart';
import '../../../../core/error/errors.dart';
import '../entity/chat_message_entity.dart';

abstract class ChatRepository {
  // Sin Either, igual que RideTrackingRepository.watchRideTrack: es un
  // stream de actualizaciones en vivo (Firestore), no una operación puntual
  // que pueda fallar de una sola vez.
  Stream<List<ChatMessageEntity>> watchMessages({required String rideId});

  Future<Either<Failure, Unit>> sendMessage({
    required String passengerId,
    required String text,
  });
}
