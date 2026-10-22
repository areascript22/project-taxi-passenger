import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/errors.dart';
import '../../domain/entity/sector_entity.dart';
import '../../domain/service/sector_service.dart';
import '../../utils/sector_geojson_parser.dart';

class SectorServiceImpl implements SectorService {
  // El AssetBundle se inyecta para poder pasarle un bundle falso en los tests,
  // igual que VoiceServiceImpl recibe un FlutterTts opcional. En producción es
  // rootBundle.
  SectorServiceImpl({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  static const String _assetKey = 'assets/json/sectors.geojson';

  // El archivo no cambia en runtime, así que se parsea una sola vez. Importa
  // porque esto se consulta en cada movimiento de la cámara del mapa.
  List<SectorEntity>? _cachedSectors;
  SectorBounds? _cachedBounds;

  @override
  Future<Either<Failure, List<SectorEntity>>> loadSectors() async {
    final cached = _cachedSectors;
    if (cached != null) return Right(cached);

    try {
      final raw = await _assetBundle.loadString(_assetKey);
      final sectors = SectorGeoJsonParser.parse(rawGeoJson: raw);

      if (sectors.isEmpty) {
        // Un archivo presente pero sin sectores legibles dejaría a la app sin
        // cobertura en silencio: se reporta como fallo para que la UI no
        // bloquee todo Riobamba creyendo que nadie está en zona.
        debugPrint(
          'SectorDebug | $_assetKey no tiene sectores legibles',
        );
        return Left(Failure(code: FailureCode.sectorsLoadFailed));
      }

      _cachedSectors = sectors;
      return Right(sectors);
    } catch (e) {
      debugPrint('SectorDebug | Error en loadSectors: $e');
      return Left(
        Failure(code: FailureCode.sectorsLoadFailed, detail: e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, SectorEntity?>> sectorFor({
    required double latitude,
    required double longitude,
  }) async {
    final sectorsResult = await loadSectors();

    return sectorsResult.fold(Left.new, (sectors) {
      final sector = SectorGeoJsonParser.sectorAt(
        sectors: sectors,
        latitude: latitude,
        longitude: longitude,
      );

      if (sector == null) {
        // Este log es la herramienta de trabajo para afinar el .geojson: un
        // punto sin sector PERO dentro de la caja de cobertura es un hueco
        // entre polígonos, no un punto fuera de Riobamba.
        final bounds = _boundsOf(sectors);
        final isHole = SectorGeoJsonParser.isWithinBounds(
          bounds: bounds,
          latitude: latitude,
          longitude: longitude,
        );
        debugPrint(
          isHole
              ? 'SectorDebug | HUECO en el .geojson: ($latitude, $longitude) '
                  'está dentro de la cobertura pero en ningún polígono'
              : 'SectorDebug | ($latitude, $longitude) está fuera de la cobertura',
        );
      }

      return Right(sector);
    });
  }

  @override
  Future<Either<Failure, SectorBounds>> coverageBounds() async {
    final sectorsResult = await loadSectors();
    return sectorsResult.fold(Left.new, (sectors) => Right(_boundsOf(sectors)));
  }

  @override
  Future<Either<Failure, bool>> isWithinCoverageBounds({
    required double latitude,
    required double longitude,
  }) async {
    final boundsResult = await coverageBounds();

    return boundsResult.fold(
      Left.new,
      (bounds) => Right(
        SectorGeoJsonParser.isWithinBounds(
          bounds: bounds,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  // loadSectors ya garantizó que la lista no está vacía, así que coverageBounds
  // del parser nunca devuelve null acá.
  SectorBounds _boundsOf(List<SectorEntity> sectors) {
    return _cachedBounds ??=
        SectorGeoJsonParser.coverageBounds(sectors: sectors)!;
  }
}
