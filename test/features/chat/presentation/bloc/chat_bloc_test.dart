import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/chat/domain/entity/chat_message_entity.dart';
import 'package:passenger_app/features/chat/domain/repository/chat_repository.dart';
import 'package:passenger_app/features/chat/presentation/bloc/chat_bloc.dart';

class MockChatRepository extends Mock implements ChatRepository {}

ChatMessageEntity _message({
  required String id,
  required String senderRole,
  required DateTime createdAt,
}) {
  return ChatMessageEntity(
    id: id,
    rideId: 'ride_1',
    senderId: '${senderRole}_uid',
    senderRole: senderRole,
    text: 'hola',
    createdAt: createdAt,
  );
}

void main() {
  late MockChatRepository repository;
  late StreamController<List<ChatMessageEntity>> messagesController;

  setUp(() {
    repository = MockChatRepository();
    messagesController = StreamController<List<ChatMessageEntity>>.broadcast();

    when(
      () => repository.watchMessages(rideId: any(named: 'rideId')),
    ).thenAnswer((_) => messagesController.stream);
  });

  tearDown(() {
    messagesController.close();
  });

  ChatBloc buildBloc() => ChatBloc(repository: repository);

  test('initial state is empty with no unread messages', () {
    final bloc = buildBloc();
    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.unreadCount, 0);
    expect(bloc.state.isSending, isFalse);
    expect(bloc.state.errorMessage, isNull);
  });

  group('WatchMessages', () {
    blocTest<ChatBloc, ChatState>(
      'forwards messages from the repository and counts unread ones sent '
      'by the driver',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
          _message(id: 'm2', senderRole: 'passenger', createdAt: DateTime(2020, 1, 1)),
        ]);
      },
      expect: () => [
        predicate<ChatState>(
          (s) => s.messages.length == 2 && s.unreadCount == 1,
        ),
      ],
      verify: (_) {
        verify(() => repository.watchMessages(rideId: 'ride_1')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'reports an error message when the messages stream errors out '
      '(ex. permission-denied de Firestore) en vez de quedarse pegado',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.addError(Exception('permission-denied'));
      },
      expect: () => [
        predicate<ChatState>(
          (s) =>
              s.messages.isEmpty &&
              s.errorMessage ==
                  'No se pudieron cargar los mensajes. Intenta de nuevo.',
        ),
      ],
    );
  });

  group('MarkMessagesRead', () {
    blocTest<ChatBloc, ChatState>(
      'clears the unread count and only counts messages that arrive after '
      'the mark-as-read moment',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
        ]);
        await Future.delayed(Duration.zero);

        bloc.add(MarkMessagesRead());
        await Future.delayed(Duration.zero);

        // Mensaje viejo (anterior al mark-as-read) + uno nuevo con fecha muy
        // en el futuro para que siempre quede después de "ahora".
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
          _message(id: 'm2', senderRole: 'driver', createdAt: DateTime(2100, 1, 1)),
        ]);
      },
      expect: () => [
        predicate<ChatState>((s) => s.unreadCount == 1), // m1 llega
        predicate<ChatState>((s) => s.unreadCount == 0), // MarkMessagesRead
        predicate<ChatState>(
          (s) => s.messages.length == 2 && s.unreadCount == 1,
        ), // solo m2 cuenta
      ],
    );
  });

  group('SendMessage', () {
    blocTest<ChatBloc, ChatState>(
      'sets isSending then clears it on success',
      setUp: () {
        when(
          () => repository.sendMessage(passengerId: 'p1', text: 'hola'),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SendMessage(passengerId: 'p1', text: 'hola')),
      expect: () => [
        predicate<ChatState>((s) => s.isSending && s.errorMessage == null),
        predicate<ChatState>((s) => !s.isSending && s.errorMessage == null),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'reports an error message on failure',
      setUp: () {
        when(
          () => repository.sendMessage(passengerId: 'p1', text: 'hola'),
        ).thenAnswer((_) async => Left(Failure(message: 'no se pudo enviar')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SendMessage(passengerId: 'p1', text: 'hola')),
      expect: () => [
        predicate<ChatState>((s) => s.isSending),
        predicate<ChatState>(
          (s) => !s.isSending && s.errorMessage == 'no se pudo enviar',
        ),
      ],
    );
  });

  group('StopWatchingMessages', () {
    blocTest<ChatBloc, ChatState>(
      'resets the state and cancels the subscription',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
        ]);
        await Future.delayed(Duration.zero);

        bloc.add(StopWatchingMessages());
      },
      expect: () => [
        predicate<ChatState>((s) => s.unreadCount == 1),
        predicate<ChatState>((s) => s.messages.isEmpty && s.unreadCount == 0),
      ],
    );

    test('close cancels the messages subscription', () async {
      final bloc = buildBloc();
      bloc.add(WatchMessages(rideId: 'ride_1'));
      await Future.delayed(Duration.zero);
      await bloc.close();
      expect(messagesController.hasListener, isFalse);
    });
  });
}
