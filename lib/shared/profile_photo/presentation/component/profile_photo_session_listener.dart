import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/bloc/session/session_bloc.dart';
import '../cubit/profile_photo_cubit.dart';

// Siembra la foto de perfil cuando la sesión se resuelve y la borra al cerrar
// sesión. Va una sola vez, por encima del router (ver main.dart), para que la
// foto esté lista desde la primera pantalla de pedir taxi sin pedirla otra vez:
// SessionBloc ya descargó los datos del pasajero para decidir si debía registrarse.
class ProfilePhotoSessionListener extends StatelessWidget {
  const ProfilePhotoSessionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        final photo = context.read<ProfilePhotoCubit>();
        if (state is SessionAuthenticated) {
          photo.set(photoUrl: state.passenger?.photoUrl);
        } else if (state is SessionUnauthenticated) {
          photo.clear();
        }
      },
      child: child,
    );
  }
}
