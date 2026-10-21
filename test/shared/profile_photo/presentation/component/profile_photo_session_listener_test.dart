import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/features/passenger_profile/domain/entity/passenger_entity.dart';
import 'package:passenger_app/shared/domain/entity/user_entity.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/profile_photo/presentation/component/profile_photo_session_listener.dart';
import 'package:passenger_app/shared/profile_photo/presentation/cubit/profile_photo_cubit.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late _MockSessionBloc session;
  late ProfilePhotoCubit photo;
  final user = UserEntity(id: 'u1', email: 'a@a.com');

  PassengerEntity passenger({String? photoUrl}) => PassengerEntity(
    id: 'u1',
    firstName: 'Ana',
    lastName: 'G',
    email: 'a@a.com',
    photoUrl: photoUrl,
  );

  setUp(() {
    session = _MockSessionBloc();
    photo = ProfilePhotoCubit();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: session),
        BlocProvider<ProfilePhotoCubit>.value(value: photo),
      ],
      child: const ProfilePhotoSessionListener(child: SizedBox()),
    ),
  );

  testWidgets('SessionAuthenticated siembra la foto del pasajero', (
    tester,
  ) async {
    whenListen(
      session,
      Stream<SessionState>.fromIterable([
        SessionAuthenticated(
          user: user,
          passenger: passenger(photoUrl: 'https://x/a.jpg'),
        ),
      ]),
      initialState: SessionUnknown(),
    );
    await pump(tester);
    await tester.pump();

    expect(photo.state, 'https://x/a.jpg');
  });

  testWidgets('SessionAuthenticated sin foto deja el avatar vacío', (
    tester,
  ) async {
    photo.set(photoUrl: 'https://x/old.jpg');
    whenListen(
      session,
      Stream<SessionState>.fromIterable([
        SessionAuthenticated(user: user, passenger: passenger()),
      ]),
      initialState: SessionUnknown(),
    );
    await pump(tester);
    await tester.pump();

    expect(photo.state, isNull);
  });

  testWidgets('SessionUnauthenticated borra la foto', (tester) async {
    photo.set(photoUrl: 'https://x/a.jpg');
    whenListen(
      session,
      Stream<SessionState>.fromIterable([SessionUnauthenticated()]),
      initialState: SessionUnknown(),
    );
    await pump(tester);
    await tester.pump();

    expect(photo.state, isNull);
  });

  testWidgets('otros estados de sesión no tocan la foto', (tester) async {
    photo.set(photoUrl: 'https://x/a.jpg');
    whenListen(
      session,
      Stream<SessionState>.fromIterable([SessionCheckFailed(user: user)]),
      initialState: SessionUnknown(),
    );
    await pump(tester);
    await tester.pump();

    expect(photo.state, 'https://x/a.jpg');
  });
}
