import 'package:passenger_app/core/error/errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/shared/account/data/repository/account_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AccountRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = AccountRepositoryImpl(dio: dio);
  });

  RequestOptions requestOptions() => RequestOptions(path: '/api/account');

  // Helper compartido: todas las llamadas pasan `options` (ver
  // AccountRepositoryImpl._deleteTimeout), así que el stub tiene que
  // matchearlo o mocktail no lo reconoce.
  When<Future<Response<dynamic>>> whenDelete() =>
      when(() => dio.delete('/api/account', options: any(named: 'options')));

  group('deleteAccount', () {
    test('returns Right(unit) when the backend confirms the deletion (204)', () async {
      whenDelete().thenAnswer(
        (_) async => Response(requestOptions: requestOptions(), statusCode: 204),
      );

      final result = await repository.deleteAccount();

      expect(result.isRight(), isTrue);
    });

    // El timeout global de DioClient (5s) no alcanza para este endpoint: con
    // él, Dio abortaba la espera mientras el server seguía borrando y el
    // reintento chocaba contra un usuario de Auth ya eliminado (500).
    test('sends the request with an extended receiveTimeout', () async {
      whenDelete().thenAnswer(
        (_) async => Response(requestOptions: requestOptions(), statusCode: 204),
      );

      await repository.deleteAccount();

      final captured = verify(
        () => dio.delete('/api/account', options: captureAny(named: 'options')),
      ).captured.single as Options;
      expect(captured.receiveTimeout, const Duration(seconds: 30));
    });

    test(
      'returns a specific Failure message when the backend responds 409 (active ride)',
      () async {
        whenDelete().thenThrow(
          DioException(
            requestOptions: requestOptions(),
            response: Response(requestOptions: requestOptions(), statusCode: 409),
          ),
        );

        final result = await repository.deleteAccount();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.code, FailureCode.accountHasActiveRide),
          (_) => fail('expected a Left'),
        );
      },
    );

    test('returns a generic Failure on any other DioException', () async {
      whenDelete().thenThrow(
        DioException(
          requestOptions: requestOptions(),
          response: Response(requestOptions: requestOptions(), statusCode: 500),
        ),
      );

      final result = await repository.deleteAccount();

      expect(result.isLeft(), isTrue);
    });

    test('returns a generic Failure on an unexpected error', () async {
      whenDelete().thenThrow(Exception('boom'));

      final result = await repository.deleteAccount();

      expect(result.isLeft(), isTrue);
    });
  });
}
