import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/profile_photo/presentation/cubit/profile_photo_cubit.dart';

void main() {
  test('el estado inicial es null (sin foto)', () {
    expect(ProfilePhotoCubit().state, isNull);
  });

  blocTest<ProfilePhotoCubit, String?>(
    'set emite la URL recibida',
    build: ProfilePhotoCubit.new,
    act: (cubit) => cubit.set(photoUrl: 'https://x/a.jpg'),
    expect: () => ['https://x/a.jpg'],
  );

  blocTest<ProfilePhotoCubit, String?>(
    'set recorta espacios alrededor de la URL',
    build: ProfilePhotoCubit.new,
    act: (cubit) => cubit.set(photoUrl: '  https://x/a.jpg '),
    expect: () => ['https://x/a.jpg'],
  );

  blocTest<ProfilePhotoCubit, String?>(
    'una URL vacía o solo espacios cuenta como sin foto',
    build: ProfilePhotoCubit.new,
    seed: () => 'https://x/a.jpg',
    act: (cubit) => cubit
      ..set(photoUrl: '')
      ..set(photoUrl: '   '),
    // El segundo set emite null otra vez: Bloc descarta estados iguales.
    expect: () => [isNull],
  );

  blocTest<ProfilePhotoCubit, String?>(
    'set(null) borra la foto',
    build: ProfilePhotoCubit.new,
    seed: () => 'https://x/a.jpg',
    act: (cubit) => cubit.set(photoUrl: null),
    expect: () => [isNull],
  );

  blocTest<ProfilePhotoCubit, String?>(
    'clear borra la foto',
    build: ProfilePhotoCubit.new,
    seed: () => 'https://x/a.jpg',
    act: (cubit) => cubit.clear(),
    expect: () => [isNull],
  );

  blocTest<ProfilePhotoCubit, String?>(
    'cambiar la foto emite la nueva URL',
    build: ProfilePhotoCubit.new,
    seed: () => 'https://x/a.jpg',
    act: (cubit) => cubit.set(photoUrl: 'https://x/b.jpg'),
    expect: () => ['https://x/b.jpg'],
  );
}
