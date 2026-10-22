import 'package:dartz/dartz.dart';

import '../../../../core/error/errors.dart';
import '../entity/sector_entity.dart';

abstract class SectorService {
  /// Los 59 sectores de Riobamba, parseados del GeoJSON que viene en los
  /// assets. Se cachean: el archivo no cambia en tiempo de ejecución.
  Future<Either<Failure, List<SectorEntity>>> loadSectors();

  /// El sector que contiene al punto.
  ///
  /// Devuelve `Right(null)` -- no un `Left` -- cuando el punto no cae en
  /// ninguno: no es un fallo, es la respuesta "está fuera de la cobertura", y
  /// quien llama tiene que poder distinguirla de un error de lectura del
  /// archivo (que sí es `Left`).
  Future<Either<Failure, SectorEntity?>> sectorFor({
    required double latitude,
    required double longitude,
  });

  /// Caja que envuelve a todos los sectores. Es la única definición de "dónde
  /// queda Riobamba" en la app: la usan el encuadre del mapa y la restricción
  /// de las sugerencias del buscador.
  Future<Either<Failure, SectorBounds>> coverageBounds();

  /// `true` si el punto está dentro de la caja de cobertura, aunque no caiga en
  /// ningún polígono. Separa los dos casos que se tratan distinto: afuera de la
  /// caja no es Riobamba; adentro pero sin sector es un hueco del dibujo.
  Future<Either<Failure, bool>> isWithinCoverageBounds({
    required double latitude,
    required double longitude,
  });
}
