// Sin Either, igual que ChatRepository.watchMessages / TripRepository
// .watchTrip: es un stream continuo de estado (conectado/desconectado), no
// una operación puntual que pueda fallar de una sola vez.
abstract class ConnectivityRepository {
  // Emite true apenas el dispositivo tiene acceso real a internet (no solo
  // una interfaz de red activa -- ver ConnectivityRepositoryImpl) y false en
  // cuanto lo pierde. Siempre emite un valor inicial al suscribirse.
  Stream<bool> watchConnection();
}
