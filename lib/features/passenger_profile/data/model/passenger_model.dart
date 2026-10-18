import '../../domain/entity/passenger_entity.dart';

/// El pasajero tal como lo devuelve `GET /api/me`.
///
/// La respuesta mezcla la identidad (nombre, email: viven en `users`) con el
/// perfil (`passenger`: foto, estado). `fcmToken` no viaja: el servidor no lo
/// expone y la app no lo necesita.
class PassengerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? photoUrl;
  final String status;

  PassengerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    required this.status,
  });

  /// `null` si la persona existe pero no tiene perfil de pasajero.
  static PassengerModel? fromMe(Map<String, dynamic> me) {
    final passenger = me['passenger'] as Map<String, dynamic>?;
    if (passenger == null) {
      return null;
    }
    return PassengerModel(
      id: me['uid'] as String? ?? '',
      firstName: me['firstName'] as String? ?? '',
      lastName: me['lastName'] as String? ?? '',
      email: me['email'] as String? ?? '',
      photoUrl: passenger['photoUrl'] as String?,
      status: passenger['status'] as String? ?? 'active',
    );
  }

  PassengerEntity toEntity() {
    return PassengerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      photoUrl: photoUrl,
      status: status,
    );
  }
}
