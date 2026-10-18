import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/app_update/data/repository/app_update_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;

  setUp(() {
    dio = MockDio();
  });

  AppUpdateRepositoryImpl buildRepository({String? version = '1.0.4-dev'}) {
    return AppUpdateRepositoryImpl(
      appId: 'passenger',
      readVersion: () async => version,
      dio: dio,
    );
  }

  RequestOptions requestOptions() =>
      RequestOptions(path: '/api/public/app-version');

  When<Future<Response<dynamic>>> whenGet() => when(
    () => dio.get(
      '/api/public/app-version',
      queryParameters: any(named: 'queryParameters'),
    ),
  );

  Response<dynamic> ok(Map<String, dynamic> body) =>
      Response(requestOptions: requestOptions(), statusCode: 200, data: body);

  group('checkUpdate', () {
    test('returns the requirement when the server says to update', () async {
      whenGet().thenAnswer(
        (_) async => ok({
          'updateRequired': true,
          'minimumVersion': '1.0.5',
          'storeUrl': 'https://play.google.com/store/apps/details?id=x',
        }),
      );

      final result = await buildRepository().checkUpdate();

      final requirement = result.getOrElse(() => throw StateError('no Right'));
      expect(requirement.updateRequired, isTrue);
      expect(requirement.minimumVersion, '1.0.5');
      expect(requirement.storeUrl, 'https://play.google.com/store/apps/details?id=x');
    });

    test('returns the requirement when the version is up to date', () async {
      whenGet().thenAnswer(
        (_) async => ok({
          'updateRequired': false,
          'minimumVersion': '1.0.4',
          'storeUrl': 'https://play.google.com/store/apps/details?id=x',
        }),
      );

      final result = await buildRepository().checkUpdate();

      expect(
        result.getOrElse(() => throw StateError('no Right')).updateRequired,
        isFalse,
      );
    });

    // El servidor ignora el sufijo y el build: se manda tal cual lo reporta el
    // sistema, junto con el id de la app.
    test('sends the app id and the raw installed version as query params', () async {
      whenGet().thenAnswer(
        (_) async => ok({
          'updateRequired': false,
          'minimumVersion': '0.0.0',
          'storeUrl': '',
        }),
      );

      await buildRepository(version: '1.0.4-dev').checkUpdate();

      final captured = verify(
        () => dio.get(
          '/api/public/app-version',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'app': 'passenger', 'version': '1.0.4-dev'});
    });

    test('treats a missing updateRequired field as not required', () async {
      whenGet().thenAnswer(
        (_) async => ok({'minimumVersion': '1.0.4', 'storeUrl': ''}),
      );

      final result = await buildRepository().checkUpdate();

      expect(
        result.getOrElse(() => throw StateError('no Right')).updateRequired,
        isFalse,
      );
    });

    test('returns Left(appUpdateCheckFailed) on a network error', () async {
      whenGet().thenThrow(
        DioException(
          requestOptions: requestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await buildRepository().checkUpdate();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.code, FailureCode.appUpdateCheckFailed),
        (_) => fail('expected Left'),
      );
    });

    test('returns Left(appUpdateCheckFailed) on a server error (500)', () async {
      whenGet().thenThrow(
        DioException(
          requestOptions: requestOptions(),
          response: Response(requestOptions: requestOptions(), statusCode: 500),
        ),
      );

      final result = await buildRepository().checkUpdate();

      expect(result.isLeft(), isTrue);
    });

    test('returns Left and never calls the server when the version cannot be read', () async {
      final result = await buildRepository(version: null).checkUpdate();

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => dio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });

    test('returns Left when the response body is not a JSON object', () async {
      whenGet().thenAnswer(
        (_) async => Response(
          requestOptions: requestOptions(),
          statusCode: 200,
          data: '<html>proxy</html>',
        ),
      );

      final result = await buildRepository().checkUpdate();

      expect(result.isLeft(), isTrue);
    });
  });
}
