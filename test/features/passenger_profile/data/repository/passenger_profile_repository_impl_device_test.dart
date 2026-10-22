import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/passenger_profile/data/repository/passenger_profile_repository_impl.dart';

class MockDio extends Mock implements Dio {}

// El token de notificaciones y el idioma ya no se escriben en Firestore: van
// al servidor (PUT /api/me/device), que identifica a la persona y a la app por
// el token de sesion.
void main() {
  late MockDio dio;
  late PassengerProfileRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = PassengerProfileRepositoryImpl(dio: dio);
  });

  Response<dynamic> noContent() => Response(
    requestOptions: RequestOptions(path: '/api/me/device'),
    statusCode: 204,
  );

  group('updateFcmToken', () {
    test('sends token and language tagged as the passenger app', () async {
      when(
        () => dio.put('/api/me/device', data: any(named: 'data')),
      ).thenAnswer((_) async => noContent());

      final result = await repository.updateFcmToken(
        passengerId: 'p1',
        token: 'tok-1',
        language: 'es',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => dio.put(
          '/api/me/device',
          data: {'app': 'passenger', 'fcmToken': 'tok-1', 'language': 'es'},
        ),
      ).called(1);
    });

    test('returns Left(fcmTokenSaveFailed) when the server rejects it', () async {
      when(() => dio.put('/api/me/device', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/device'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/me/device'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository.updateFcmToken(
        passengerId: 'p1',
        token: 'tok-1',
        language: 'es',
      );

      result.fold(
        (failure) => expect(failure.code, FailureCode.fcmTokenSaveFailed),
        (_) => fail('expected Left'),
      );
    });
  });

  group('updateLanguage', () {
    test('sends only the language', () async {
      when(
        () => dio.put('/api/me/device', data: any(named: 'data')),
      ).thenAnswer((_) async => noContent());

      final result = await repository.updateLanguage(
        passengerId: 'p1',
        language: 'en',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => dio.put(
          '/api/me/device',
          data: {'app': 'passenger', 'language': 'en'},
        ),
      ).called(1);
    });

    test('returns Left(pushLanguageSaveFailed) on a network error', () async {
      when(() => dio.put('/api/me/device', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/device'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.updateLanguage(
        passengerId: 'p1',
        language: 'en',
      );

      result.fold(
        (failure) => expect(failure.code, FailureCode.pushLanguageSaveFailed),
        (_) => fail('expected Left'),
      );
    });
  });
}
