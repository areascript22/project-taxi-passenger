import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/features/passenger_profile/domain/repository/passenger_profile_repository.dart';
import 'package:passenger_app/features/passenger_profile/presentation/bloc/passenger_onboarding_bloc.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';
import 'package:passenger_app/shared/image_picker/service/profile_image_picker_service.dart';

class _MockPassengerProfileRepository extends Mock
    implements PassengerProfileRepository {}

class _MockProfileImagePickerService extends Mock
    implements ProfileImagePickerService {}

class _FakePassengerEntity extends Fake implements PassengerEntity {}

void main() {
  late _MockPassengerProfileRepository passengerProfileRepository;
  late _MockProfileImagePickerService imagePickerService;
  final user = UserEntity(id: 'u1', email: 'a@a.com');
  final image = File('fake_path.png');

  setUpAll(() {
    registerFallbackValue(_FakePassengerEntity());
    registerFallbackValue(ProfileImageSource.camera);
  });

  setUp(() {
    passengerProfileRepository = _MockPassengerProfileRepository();
    imagePickerService = _MockProfileImagePickerService();
  });

  PassengerOnboardingBloc buildBloc() => PassengerOnboardingBloc(
    passengerProfileRepository: passengerProfileRepository,
    imagePickerService: imagePickerService,
  );

  test('el estado inicial no tiene usuario ni está enviando', () {
    final state = buildBloc().state;
    expect(state.user, isNull);
    expect(state.isSubmitting, isFalse);
    expect(state.registrationSuccess, isFalse);
  });

  group('PassengerOnboardingStarted', () {
    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'guarda el usuario en el estado',
      build: buildBloc,
      act: (bloc) => bloc.add(PassengerOnboardingStarted(user)),
      expect: () => [
        isA<PassengerOnboardingState>().having((s) => s.user, 'user', user),
      ],
    );
  });

  group('PassengerOnboardingImagePicked', () {
    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'emite isPickingImage true/false y guarda el file elegido',
      build: () {
        when(
          () => imagePickerService.pickImage(
            source: any(named: 'source'),
          ),
        ).thenAnswer((_) async => Right(image));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        PassengerOnboardingImagePicked(ProfileImageSource.gallery),
      ),
      expect: () => [
        isA<PassengerOnboardingState>().having(
          (s) => s.isPickingImage,
          'isPickingImage',
          isTrue,
        ),
        isA<PassengerOnboardingState>()
            .having((s) => s.isPickingImage, 'isPickingImage', isFalse)
            .having((s) => s.profileImage, 'profileImage', image),
      ],
    );

    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'usuario cancela la selección (Right(null)): no guarda imagen ni error',
      build: () {
        when(
          () => imagePickerService.pickImage(source: any(named: 'source')),
        ).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        PassengerOnboardingImagePicked(ProfileImageSource.camera),
      ),
      expect: () => [
        isA<PassengerOnboardingState>().having(
          (s) => s.isPickingImage,
          'isPickingImage',
          isTrue,
        ),
        isA<PassengerOnboardingState>()
            .having((s) => s.isPickingImage, 'isPickingImage', isFalse)
            .having((s) => s.profileImage, 'profileImage', isNull),
      ],
    );

    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'emite errorMessage cuando el picker falla',
      build: () {
        when(
          () => imagePickerService.pickImage(source: any(named: 'source')),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'permiso denegado')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        PassengerOnboardingImagePicked(ProfileImageSource.camera),
      ),
      expect: () => [
        isA<PassengerOnboardingState>().having(
          (s) => s.isPickingImage,
          'isPickingImage',
          isTrue,
        ),
        isA<PassengerOnboardingState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'permiso denegado',
        ),
      ],
    );
  });

  group('PassengerOnboardingSubmitted', () {
    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'no-op si todavía no hay usuario en el estado',
      build: buildBloc,
      act: (bloc) => bloc.add(
        PassengerOnboardingSubmitted(firstName: 'Ana', lastName: 'Gómez'),
      ),
      expect: () => <PassengerOnboardingState>[],
      verify: (_) {
        verifyNever(
          () => passengerProfileRepository.registerPassenger(
            passenger: any(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        );
      },
    );

    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'registra al pasajero y marca registrationSuccess',
      build: () {
        when(
          () => passengerProfileRepository.registerPassenger(
            passenger: any(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => PassengerOnboardingState(user: user),
      act: (bloc) => bloc.add(
        PassengerOnboardingSubmitted(firstName: 'Ana', lastName: 'Gómez'),
      ),
      expect: () => [
        isA<PassengerOnboardingState>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          isTrue,
        ),
        isA<PassengerOnboardingState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having(
              (s) => s.registrationSuccess,
              'registrationSuccess',
              isTrue,
            ),
      ],
      verify: (_) {
        final captured = verify(
          () => passengerProfileRepository.registerPassenger(
            passenger: captureAny(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).captured;
        final passenger = captured.single as PassengerEntity;
        expect(passenger.firstName, 'Ana');
        expect(passenger.lastName, 'Gómez');
        expect(passenger.id, user.id);
      },
    );

    blocTest<PassengerOnboardingBloc, PassengerOnboardingState>(
      'emite errorMessage si el registro falla',
      build: () {
        when(
          () => passengerProfileRepository.registerPassenger(
            passenger: any(named: 'passenger'),
            profileImage: any(named: 'profileImage'),
          ),
        ).thenAnswer(
          (_) async => Left(Failure(message: 'email ya registrado')),
        );
        return buildBloc();
      },
      seed: () => PassengerOnboardingState(user: user),
      act: (bloc) => bloc.add(
        PassengerOnboardingSubmitted(firstName: 'Ana', lastName: 'Gómez'),
      ),
      expect: () => [
        isA<PassengerOnboardingState>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          isTrue,
        ),
        isA<PassengerOnboardingState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'email ya registrado',
            ),
      ],
    );
  });
}
