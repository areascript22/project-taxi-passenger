import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:passenger_app/shared/image_picker/service/profile_image_picker_service.dart';

class _MockPassengerProfileRepository extends Mock
    implements PassengerProfileRepository {}

class _MockProfileImagePickerService extends Mock
    implements ProfileImagePickerService {}

class _FakePassengerEntity extends Fake implements PassengerEntity {}

void main() {
  late _MockPassengerProfileRepository passengerProfileRepository;
  late _MockProfileImagePickerService imagePickerService;
  final passenger = PassengerEntity(
    id: 'p1',
    firstName: 'Ana',
    lastName: 'Gómez',
    email: 'a@a.com',
  );
  final image = File('fake_path.png');

  setUpAll(() {
    registerFallbackValue(_FakePassengerEntity());
    registerFallbackValue(ProfileImageSource.camera);
  });

  setUp(() {
    passengerProfileRepository = _MockPassengerProfileRepository();
    imagePickerService = _MockProfileImagePickerService();
  });

  ProfileBloc buildBloc() => ProfileBloc(
    passengerProfileRepository: passengerProfileRepository,
    imagePickerService: imagePickerService,
  );

  test('el estado inicial no está cargando ni tiene pasajero', () {
    final state = buildBloc().state;
    expect(state.isLoading, isFalse);
    expect(state.passenger, isNull);
  });

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emite isLoading true y luego el pasajero cargado',
      build: () {
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Right(passenger));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(passengerId: 'p1')),
      expect: () => [
        isA<ProfileState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<ProfileState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.passenger, 'passenger', passenger),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'errorMessage genérico cuando el repo devuelve Left',
      build: () {
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'network error')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(passengerId: 'p1')),
      expect: () => [
        isA<ProfileState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<ProfileState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'No se pudo cargar tu información',
            ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'errorMessage también cuando el repo devuelve Right(null) (pasajero inexistente)',
      build: () {
        when(
          () => passengerProfileRepository.getPassenger(
            passengerId: any(named: 'passengerId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(passengerId: 'p1')),
      expect: () => [
        isA<ProfileState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<ProfileState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'No se pudo cargar tu información',
        ),
      ],
    );
  });

  group('ProfileEditStarted', () {
    blocTest<ProfileBloc, ProfileState>(
      'limpia localImage y errorMessage previos',
      build: buildBloc,
      seed: () => ProfileState(
        localImage: File('previo.png'),
        errorMessage: 'error viejo',
      ),
      act: (bloc) => bloc.add(ProfileEditStarted()),
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.localImage, 'localImage', isNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );
  });

  group('ProfileImagePicked', () {
    blocTest<ProfileBloc, ProfileState>(
      'guarda la imagen elegida en localImage',
      build: () {
        when(
          () => imagePickerService.pickImage(source: any(named: 'source')),
        ).thenAnswer((_) async => Right(image));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ProfileImagePicked(ProfileImageSource.gallery)),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.isPickingImage,
          'isPickingImage',
          isTrue,
        ),
        isA<ProfileState>()
            .having((s) => s.isPickingImage, 'isPickingImage', isFalse)
            .having((s) => s.localImage, 'localImage', image),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'cancelación (Right(null)) no cambia localImage',
      build: () {
        when(
          () => imagePickerService.pickImage(source: any(named: 'source')),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(ProfileImagePicked(ProfileImageSource.camera)),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.isPickingImage,
          'isPickingImage',
          isTrue,
        ),
        isA<ProfileState>()
            .having((s) => s.isPickingImage, 'isPickingImage', isFalse)
            .having((s) => s.localImage, 'localImage', isNull),
      ],
    );
  });

  group('ProfileUpdateSubmitted', () {
    blocTest<ProfileBloc, ProfileState>(
      'no-op si todavía no hay pasajero cargado',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(ProfileUpdateSubmitted(firstName: 'X', lastName: 'Y')),
      expect: () => <ProfileState>[],
    );

    blocTest<ProfileBloc, ProfileState>(
      'actualiza el pasajero y marca updateSuccess + limpia localImage',
      build: () {
        when(
          () => passengerProfileRepository.updatePassenger(
            passenger: any(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer((_) async => Right(passenger.copyWith()));
        return buildBloc();
      },
      seed: () => ProfileState(passenger: passenger, localImage: image),
      act: (bloc) =>
          bloc.add(ProfileUpdateSubmitted(firstName: 'Ana2', lastName: 'G2')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          isTrue,
        ),
        isA<ProfileState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.updateSuccess, 'updateSuccess', isTrue)
            .having((s) => s.localImage, 'localImage', isNull),
      ],
      verify: (_) {
        final captured = verify(
          () => passengerProfileRepository.updatePassenger(
            passenger: captureAny(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).captured;
        final sent = captured.single as PassengerEntity;
        expect(sent.firstName, 'Ana2');
        expect(sent.lastName, 'G2');
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emite errorMessage si falla la actualización',
      build: () {
        when(
          () => passengerProfileRepository.updatePassenger(
            passenger: any(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer((_) async => Left(Failure(message: 'no autorizado')));
        return buildBloc();
      },
      seed: () => ProfileState(passenger: passenger),
      act: (bloc) =>
          bloc.add(ProfileUpdateSubmitted(firstName: 'Ana2', lastName: 'G2')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          isTrue,
        ),
        isA<ProfileState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', 'no autorizado'),
      ],
    );
  });
}
