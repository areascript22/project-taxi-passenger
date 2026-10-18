/// Cuanto lleva buscandose conductor, para el contador del popup "Buscando
/// conductor".
///
/// Es un contador HACIA ARRIBA y no una cuenta regresiva porque la duracion de la
/// busqueda ya no la fija la app: la decide el servidor con los anillos de
/// busqueda (radio y espera de cada uno), que un administrador puede cambiar. La
/// app no sabe cuanto va a durar, asi que una cuenta regresiva seria un numero
/// inventado. Lo unico que si sabe es cuanto lleva esperando.
///
/// Funciones puras para poder probarlas sin reloj ni widgets.
Duration searchElapsed({
  required DateTime now,
  required DateTime openedAt,
  int? rideCreatedAtMillis,
}) {
  // Al reanudar una solicitud que ya existia (la app se cerro y se reabrio) se
  // cuenta desde que el SERVIDOR la creo, no desde que se abrio el popup: el
  // pasajero lleva esperando desde entonces. createdAt es la hora del servidor
  // (ServerValue.timestamp), asi que no depende de que el reloj del telefono
  // este bien -- pero si el telefono esta atrasado la diferencia puede salir
  // negativa, y un contador nunca muestra tiempo negativo.
  final startedAt =
      rideCreatedAtMillis == null
          ? openedAt
          : DateTime.fromMillisecondsSinceEpoch(rideCreatedAtMillis);
  final elapsed = now.difference(startedAt);
  return elapsed.isNegative ? Duration.zero : elapsed;
}

/// "m:ss" (p. ej. `0:07`, `1:03`). Acotado a una hora: una solicitud no deberia
/// durar tanto, pero un contador no debe desbordar el chip si pasa.
String formatSearchElapsed(Duration elapsed) {
  final totalSeconds = elapsed.inSeconds.clamp(0, 3599);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
