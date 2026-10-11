import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/ride_tracking/data/repository/ride_tracking_repository_impl.dart';

class MockDio extends Mock implements Dio {}

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

void main() {
  late MockDio dio;
  late MockFirebaseDatabase database;
  late RideTrackingRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    database = MockFirebaseDatabase();
    repository = RideTrackingRepositoryImpl(database: database, dio: dio);
  });

  RequestOptions requestOptions() =>
      RequestOptions(path: '/api/rides/p1/start');

  group('confirmOnTheWay', () {
    // Ya no escribe directo en Realtime Database: pasa por el servidor, que
    // verifica que es el pasajero dueño y que el conductor ya llegó.
    test('posts to the server and never touches the database', () async {
      when(() => dio.post('/api/rides/p1/start')).thenAnswer(
        (_) async => Response(requestOptions: requestOptions(), statusCode: 204),
      );

      final result = await repository.confirmOnTheWay(passengerId: 'p1');

      expect(result.isRight(), isTrue);
      verify(() => dio.post('/api/rides/p1/start')).called(1);
      verifyZeroInteractions(database);
    });

    for (final statusCode in [403, 404, 409, 500]) {
      test('returns Left(confirmFailed) when the server answers $statusCode', () async {
        when(() => dio.post('/api/rides/p1/start')).thenThrow(
          DioException(
            requestOptions: requestOptions(),
            response: Response(
              requestOptions: requestOptions(),
              statusCode: statusCode,
            ),
          ),
        );

        final result = await repository.confirmOnTheWay(passengerId: 'p1');

        result.fold(
          (failure) => expect(failure.code, FailureCode.confirmFailed),
          (_) => fail('expected Left'),
        );
      });
    }

    test('returns Left(confirmFailed) on a network error', () async {
      when(() => dio.post('/api/rides/p1/start')).thenThrow(
        DioException(
          requestOptions: requestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.confirmOnTheWay(passengerId: 'p1');

      expect(result.isLeft(), isTrue);
    });
  });
}
