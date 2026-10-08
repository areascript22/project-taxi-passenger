import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/chat/domain/entity/chat_message_entity.dart';
import 'package:passenger_app/features/chat/domain/repository/chat_repository.dart';
import 'package:passenger_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:passenger_app/shared/connectivity/domain/repository/connectivity_repository.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockConnectivityRepository extends Mock
    implements ConnectivityRepository {}

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
  late MockConnectivityRepository connectivityRepository;
  late StreamController<List<ChatMessageEntity>> messagesController;
  late StreamController<bool> connectivityController;

  setUp(() {
    repository = MockChatRepository();
    connectivityRepository = MockConnectivityRepository();
    messagesController = StreamController<List<ChatMessageEntity>>.broadcast();
    connectivityController = StreamController<bool>.broadcast();

    when(
      () => repository.watchMessages(rideId: any(named: 'rideId')),
    ).thenAnswer((_) => messagesController.stream);
    when(
      () => connectivityRepository.watchConnection(),
    ).thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    messagesController.close();
    connectivityController.close();
  });

  ChatBloc buildBloc() => ChatBloc(
    repository: repository,
    connectivityRepository: connectivityRepository,
  );

  test('initial state is empty with no unread messages', () {
    final bloc = buildBloc();
    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.unreadCount, 0);
    expect(bloc.state.isSending, isFalse);
    expect(bloc.state.errorCode, isNull);
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
              s.errorCode != null,
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
        predicate<ChatState>((s) => s.isSending && s.errorCode == null),
        predicate<ChatState>((s) => !s.isSending && s.errorCode == null),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'reports an error message on failure',
      setUp: () {
        when(
          () => repository.sendMessage(passengerId: 'p1', text: 'hola'),
        ).thenAnswer((_) async => Left(Failure(code: FailureCode.unexpected)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SendMessage(passengerId: 'p1', text: 'hola')),
      expect: () => [
        predicate<ChatState>((s) => s.isSending),
        predicate<ChatState>(
          (s) => !s.isSending && s.errorCode != null,
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

  group('Connectivity reconnection', () {
    blocTest<ChatBloc, ChatState>(
      'resubscribes to watchMessages when the connection is restored after '
      'the stream errored out',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.addError(Exception('unavailable'));
        await Future.delayed(Duration.zero);

        connectivityController.add(true);
        await Future.delayed(Duration.zero);
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
        ]);
      },
      expect: () => [
        predicate<ChatState>(
          (s) =>
              s.errorCode != null,
        ),
        predicate<ChatState>((s) => s.errorCode == null), // reintento
        predicate<ChatState>(
          (s) => s.messages.length == 1 && s.errorCode == null,
        ),
      ],
      verify: (_) {
        verify(() => repository.watchMessages(rideId: 'ride_1')).called(2);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'does not resubscribe when the stream is already healthy',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(WatchMessages(rideId: 'ride_1'));
        await Future.delayed(Duration.zero);
        messagesController.add([
          _message(id: 'm1', senderRole: 'driver', createdAt: DateTime(2020, 1, 1)),
        ]);
        await Future.delayed(Duration.zero);

        connectivityController.add(true);
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        predicate<ChatState>((s) => s.messages.length == 1),
      ],
      verify: (_) {
        verify(() => repository.watchMessages(rideId: 'ride_1')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'ignores connectivity restored events before any WatchMessages was '
      'ever requested',
      build: buildBloc,
      act: (bloc) async {
        connectivityController.add(true);
        await Future.delayed(Duration.zero);
      },
      expect: () => [],
      verify: (_) {
        verifyNever(() => repository.watchMessages(rideId: any(named: 'rideId')));
      },
    );
  });

  group('Permission-denied retry (race con createChatThread server-side)', () {
    test(
      'retries a permission-denied error and recovers automatically once '
      'the parent doc becomes readable',
      () {
        fakeAsync((async) {
          final bloc = buildBloc();
          bloc.add(WatchMessages(rideId: 'ride_1'));
          async.elapse(Duration.zero);

          messagesController.addError(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );
          async.elapse(Duration.zero);

          // Silencioso a propósito mientras reintenta -- no debe parpadear
          // un error que se va a resolver solo en un instante.
          expect(bloc.state.errorCode, isNull);

          async.elapse(const Duration(milliseconds: 1200));
          messagesController.add([
            _message(
              id: 'm1',
              senderRole: 'driver',
              createdAt: DateTime(2020, 1, 1),
            ),
          ]);
          async.elapse(Duration.zero);

          expect(bloc.state.messages.length, 1);
          expect(bloc.state.errorCode, isNull);
          verify(() => repository.watchMessages(rideId: 'ride_1')).called(2);

          bloc.close();
        });
      },
    );

    test(
      'gives up after exhausting retries and shows the error message',
      () {
        fakeAsync((async) {
          final bloc = buildBloc();
          bloc.add(WatchMessages(rideId: 'ride_1'));
          async.elapse(Duration.zero);

          FirebaseException permissionDenied() => FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          );

          // Intento inicial + 4 reintentos = 5 suscripciones en total antes
          // de rendirse (ver ChatBloc._maxPermissionRetries).
          messagesController.addError(permissionDenied());
          async.elapse(Duration.zero);
          async.elapse(const Duration(milliseconds: 1200));

          messagesController.addError(permissionDenied());
          async.elapse(Duration.zero);
          async.elapse(const Duration(milliseconds: 1200));

          messagesController.addError(permissionDenied());
          async.elapse(Duration.zero);
          async.elapse(const Duration(milliseconds: 1200));

          messagesController.addError(permissionDenied());
          async.elapse(Duration.zero);
          async.elapse(const Duration(milliseconds: 1200));

          messagesController.addError(permissionDenied());
          async.elapse(Duration.zero);

          expect(
            bloc.state.errorCode,
            FailureCode.chatMessagesLoadFailed,
          );
          verify(() => repository.watchMessages(rideId: 'ride_1')).called(5);

          bloc.close();
        });
      },
    );

    test(
      'does not retry a plain (non-Firestore) error -- reports it right away',
      () {
        fakeAsync((async) {
          final bloc = buildBloc();
          bloc.add(WatchMessages(rideId: 'ride_1'));
          async.elapse(Duration.zero);

          messagesController.addError(Exception('some other failure'));
          async.elapse(Duration.zero);

          expect(
            bloc.state.errorCode,
            FailureCode.chatMessagesLoadFailed,
          );
          verify(() => repository.watchMessages(rideId: 'ride_1')).called(1);

          bloc.close();
        });
      },
    );
  });
}
