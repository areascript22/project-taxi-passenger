import 'package:get_it/get_it.dart';

import '../data/service/sector_service_impl.dart';
import '../domain/service/sector_service.dart';

void initSectorDI(GetIt sl) {
  // LazySingleton y no factory: la instancia guarda el GeoJSON ya parseado, y
  // una factory volvería a leer y parsear el archivo en cada consulta (el mapa
  // consulta en cada movimiento de cámara).
  sl.registerLazySingleton<SectorService>(() => SectorServiceImpl());
}
