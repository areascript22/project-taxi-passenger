import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/passenger_profile/data/repository/passenger_profile_repository_impl.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';

class MockDio extends Mock implements Dio {}

// El perfil del pasajero se lee de GET /api/me y se guarda con
// PUT /api/me/passenger-profile: ya no se toca Firestore.
void main() {
  late MockDio dio;
  late PassengerProfileRepositoryImpl repository;
  String? uploadedPath;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    uploadedPath = null;
    repository = PassengerProfileRepositoryImpl(
      dio: dio,
      photoUploader: ({required String path, required File file}) async {
        uploadedPath = path;
        return 'https://storage/photo.jpg';
      },
    );
  });

  Response<dynamic> ok(Map<String, dynamic> body) => Response(
    requestOptions: RequestOptions(path: '/api/me'),
    statusCode: 200,
    data: body,
  );

  Map<String, dynamic> me({Map<String, dynamic>? passenger}) => {
    'id': 'u-1',
    'uid': 'uid-1',
    'email': 'luis@test.com',
    'displayName': 'Luis Mora',
    'firstName': 'Luis',
    'lastName': 'Mora',
    'role': 'user',
    'blocked': false,
    'driver': null,
    'passenger': passenger,
  };

  final passenger = PassengerEntity(
    id: 'uid-1',
    firstName: 'Luis',
    lastName: 'Mora',
    email: 'luis@test.com',
    photoUrl: 'https://google/photo.jpg',
  );

  Response<dynamic> saved() => Response(
    requestOptions: RequestOptions(path: '/api/me/passenger-profile'),
    statusCode: 200,
    data: <String, dynamic>{},
  );

  void stubPut() {
    when(
      () => dio.put(
        '/api/me/passenger-profile',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => saved());
  }

  Map<String, dynamic> sentBody() {
    return verify(
      () => dio.put(
        '/api/me/passenger-profile',
        data: captureAny(named: 'data'),
        options: any(named: 'options'),
      ),
    ).captured.single as Map<String, dynamic>;
  }

  group('getPassenger', () {
    test('maps /api/me to the passenger entity', () async {
      when(() => dio.get('/api/me')).thenAnswer(
        (_) async => ok(
          me(passenger: {'photoUrl': 'https://p/l.jpg', 'status': 'active'}),
        ),
      );

      final result = await repository.getPassenger(passengerId: 'uid-1');

      final entity = result.getOrElse(() => null)!;
      expect(entity.id, 'uid-1');
      expect(entity.firstName, 'Luis');
      expect(entity.lastName, 'Mora');
      expect(entity.email, 'luis@test.com');
      expect(entity.photoUrl, 'https://p/l.jpg');
      expect(entity.status, 'active');
    });

    test('returns Right(null) when there is no passenger profile', () async {
      when(() => dio.get('/api/me')).thenAnswer((_) async => ok(me()));

      final result = await repository.getPassenger(passengerId: 'uid-1');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    });

    test('returns a failure when the request fails', () async {
      when(() => dio.get('/api/me')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/me')),
      );

      final result = await repository.getPassenger(passengerId: 'uid-1');

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.passengerProfileCheckFailed,
      );
    });
  });

  group('registerPassenger', () {
    test('sends the profile to the server without touching Storage', () async {
      stubPut();

      final result = await repository.registerPassenger(passenger: passenger);

      expect(result.isRight(), isTrue);
      expect(uploadedPath, isNull);
      final body = sentBody();
      expect(body['firstName'], 'Luis');
      expect(body['lastName'], 'Mora');
      expect(body['photoUrl'], 'https://google/photo.jpg');
    });

    test('uploads the photo under the passenger uid and sends its URL',
        () async {
      stubPut();

      await repository.registerPassenger(
        passenger: passenger,
        profileImage: File('photo.jpg'),
      );

      expect(uploadedPath, 'passenger_profile_photos/uid-1.jpg');
      expect(sentBody()['photoUrl'], 'https://storage/photo.jpg');
    });

    test('returns profileSaveFailed when the server rejects it', () async {
      when(
        () => dio.put(
          '/api/me/passenger-profile',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/me/passenger-profile'),
        ),
      );

      final result = await repository.registerPassenger(passenger: passenger);

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.profileSaveFailed,
      );
    });
  });

  group('updatePassenger', () {
    test('returns the entity with the new photo URL', () async {
      stubPut();

      final result = await repository.updatePassenger(
        passenger: passenger,
        profileImage: File('photo.jpg'),
      );

      final updated = result.getOrElse(() => passenger);
      expect(updated.photoUrl, 'https://storage/photo.jpg');
      expect(sentBody()['photoUrl'], 'https://storage/photo.jpg');
    });

    test('omits photoUrl when the passenger has none', () async {
      stubPut();

      await repository.updatePassenger(
        passenger: PassengerEntity(
          id: 'uid-1',
          firstName: 'Luis',
          lastName: 'Mora',
          email: 'luis@test.com',
        ),
      );

      expect(sentBody().containsKey('photoUrl'), isFalse);
    });

    test('returns profileUpdateFailed when the photo upload fails', () async {
      final failing = PassengerProfileRepositoryImpl(
        dio: dio,
        photoUploader: ({required String path, required File file}) async {
          throw Exception('storage down');
        },
      );

      final result = await failing.updatePassenger(
        passenger: passenger,
        profileImage: File('photo.jpg'),
      );

      expect(
        result.fold((f) => f.code, (_) => null),
        FailureCode.profileUpdateFailed,
      );
      verifyNever(
        () => dio.put(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });
  });
}
