import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/chat_message_entity.dart';
import '../../domain/repository/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio = DioClient.instance;

  @override
  Stream<List<ChatMessageEntity>> watchMessages({required String rideId}) {
    debugPrint(
      'ChatFlowDebug | ChatRepositoryImpl.watchMessages -> query sobre '
      'chats/$rideId/messages',
    );
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(rideId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'ChatFlowDebug | ChatRepositoryImpl.watchMessages -> snapshot '
            'rideId=$rideId docs=${snapshot.docs.length} '
            'fromCache=${snapshot.metadata.isFromCache} '
            'hasPendingWrites=${snapshot.metadata.hasPendingWrites}',
          );
          return snapshot.docs
              .map(
                (doc) => ChatMessageModel.fromMap(
                  id: doc.id,
                  rideId: rideId,
                  map: doc.data(),
                ).toEntity(),
              )
              .toList();
        });
  }

  @override
  Future<Either<Failure, Unit>> sendMessage({
    required String passengerId,
    required String text,
  }) async {
    try {
      await _dio.post('/api/rides/$passengerId/messages', data: {'text': text});
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('ChatDebug | Error en sendMessage: $e');
      if (e.response?.statusCode == 403) {
        return Left(
          Failure(code: FailureCode.chatWriteNotAllowed),
        );
      }
      if (e.response?.statusCode == 409) {
        return Left(
          Failure(code: FailureCode.chatRideFinished),
        );
      }
      return Left(
        Failure(code: FailureCode.chatSendFailed),
      );
    } catch (e) {
      debugPrint('ChatDebug | Error inesperado en sendMessage: $e');
      return Left(
        Failure(code: FailureCode.chatSendFailed),
      );
    }
  }
}
