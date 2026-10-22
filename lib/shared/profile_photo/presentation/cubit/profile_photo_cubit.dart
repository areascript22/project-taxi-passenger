import 'package:flutter_bloc/flutter_bloc.dart';

// La foto de perfil del pasajero tal como se ve FUERA de la pantalla de perfil
// (hoy, el avatar de la pantalla de pedir taxi). El estado es la URL, o null si
// no hay foto.
//
// Vive durante toda la sesión (singleton de GetIt, provisto una vez en
// main.dart) y NO cuelga de SessionBloc a propósito: refrescar la foto al editar
// el perfil exigiría volver a emitir SessionAuthenticated, y esa emisión es una
// señal que otras pantallas escuchan para decidir a dónde navegar (ver
// ride_tracking_screen y la navegación desde un push). Aquí solo se siembra
// cuando la sesión se resuelve (ProfilePhotoSessionListener) y se actualiza
// cuando el pasajero cambia su foto.
class ProfilePhotoCubit extends Cubit<String?> {
  ProfilePhotoCubit() : super(null);

  // Una URL vacía cuenta como "sin foto".
  void set({required String? photoUrl}) {
    final value = photoUrl?.trim();
    emit(value == null || value.isEmpty ? null : value);
  }

  // Al cerrar sesión: que el siguiente usuario del teléfono no vea la foto del
  // anterior.
  void clear() => emit(null);
}
