import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import 'package:passenger_app/shared/sectors/domain/entity/sector_entity.dart';
import 'package:passenger_app/shared/presentation/failure_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/map_picker/map_picker_bloc.dart';

class MapPickerScreen extends StatelessWidget {
  final PlaceEntity? initialPlace;

  const MapPickerScreen({super.key, this.initialPlace});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<MapPickerBloc>()
        ..add(
          MapPickerStarted(
            latitude: initialPlace?.latitude,
            longitude: initialPlace?.longitude,
          ),
        ),
      child: const MapPickerView(),
    );
  }
}

class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  GoogleMapController? _mapController;
  double? _pendingLatitude;
  double? _pendingLongitude;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraIdle() {
    // Sin arrastre todavia (primer idle al crear el mapa) el centro es el que
    // resolvio el bloc.
    final current = context.read<MapPickerBloc>().state;
    context.read<MapPickerBloc>().add(
      MapCameraIdle(
        latitude: _pendingLatitude ?? current.latitude,
        longitude: _pendingLongitude ?? current.longitude,
      ),
    );
  }

  void _onAccept(MapPickerState state) {
    Navigator.of(context).pop(
      PlaceEntity(
        address: state.address!,
        latitude: state.latitude,
        longitude: state.longitude,
        formattedAddress: state.address,
      ),
    );
  }

  // Sin bounds (archivo ilegible) el mapa queda libre, como antes: es preferible
  // a dejar al pasajero encerrado en un recuadro de coordenadas inventadas.
  CameraTargetBounds _cameraBounds(SectorBounds? bounds) {
    if (bounds == null) return CameraTargetBounds.unbounded;

    return CameraTargetBounds(
      LatLngBounds(
        southwest: LatLng(bounds.minLatitude, bounds.minLongitude),
        northeast: LatLng(bounds.maxLatitude, bounds.maxLongitude),
      ),
    );
  }

  // Los 59 sectores dibujados encima del mapa: el pasajero ve de una vez dónde
  // puede pedir, en vez de descubrirlo cuando el botón no se habilita.
  Set<Polygon> _sectorPolygons(
    List<SectorEntity> sectors,
    ColorScheme colorScheme,
  ) {
    return sectors.indexed.map((entry) {
      final (index, sector) = entry;

      return Polygon(
        // El nombre no alcanza como id: varios sectores pueden compartirlo si un
        // MultiPolygon se partió en dos.
        polygonId: PolygonId('sector_${index}_${sector.name}'),
        points:
            sector.ring
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
        strokeWidth: 1,
        strokeColor: colorScheme.primary.withValues(alpha: 0.6),
        fillColor: colorScheme.primary.withValues(alpha: 0.08),
        consumeTapEvents: false,
      );
    }).toSet();
  }

  static bool _isResolving(MapPickerState state) =>
      state.status == MapPickerStatus.initial ||
      state.status == MapPickerStatus.resolvingCenter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).mapPickerTitle),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Los polígonos y el límite de cámara salen del state porque se leen
          // del .geojson de forma asíncrona: el mapa se dibuja primero y se
          // recompone cuando los sectores están cargados.
          BlocBuilder<MapPickerBloc, MapPickerState>(
            buildWhen:
                (previous, current) =>
                    previous.sectors != current.sectors ||
                    previous.coverageBounds != current.coverageBounds ||
                    _isResolving(previous) != _isResolving(current),
            builder: (context, state) {
              // El centro (punto conocido, ultima ubicacion, GPS o Riobamba) se
              // resuelve antes de dibujar: asi el mapa abre ya en su sitio y no
              // salta desde otro lugar.
              if (_isResolving(state)) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(state.latitude, state.longitude),
                  zoom: 16,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: (position) {
                  _pendingLatitude = position.target.latitude;
                  _pendingLongitude = position.target.longitude;
                },
                onCameraIdle: _onCameraIdle,
                zoomControlsEnabled: false,
                // Limita el CENTRO de la cámara, que es justo donde está el
                // pin: el usuario puede ver los bordes pero no poner el pin
                // fuera de Riobamba.
                cameraTargetBounds: _cameraBounds(state.coverageBounds),
                polygons: _sectorPolygons(state.sectors, colorScheme),
              );
            },
          ),

          IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: BlocBuilder<MapPickerBloc, MapPickerState>(
                buildWhen:
                    (previous, current) => previous.status != current.status,
                builder: (context, state) {
                  final isOutOfCoverage =
                      state.status == MapPickerStatus.outOfCoverage;

                  return Icon(
                    isOutOfCoverage
                        ? Icons.location_off_rounded
                        : Icons.location_pin,
                    size: 48,
                    color:
                        isOutOfCoverage
                            ? colorScheme.error
                            : colorScheme.primary,
                  );
                },
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AddressBubble(),
                    const SizedBox(height: 16),
                    BlocBuilder<MapPickerBloc, MapPickerState>(
                      builder: (context, state) {
                        return CustomButton(
                          textButton: AppLocalizations.of(context).mapPickerConfirm,
                          onTap: state.status == MapPickerStatus.addressReady
                              ? () => _onAccept(state)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressBubble extends StatelessWidget {
  const _AddressBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<MapPickerBloc, MapPickerState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, MapPickerState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    if (state.status == MapPickerStatus.loadingAddress) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).mapPickerSearching,
            style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
          ),
        ],
      );
    }

    if (state.status == MapPickerStatus.error) {
      return Text(
        state.errorCode != null
            ? context.failureText(state.errorCode!)
            : AppLocalizations.of(context).mapPickerAddressFailed,
        style: TextStyle(fontSize: 14, color: colorScheme.error),
      );
    }

    if (state.status == MapPickerStatus.outOfCoverage) {
      return Row(
        children: [
          Icon(Icons.location_off_rounded, color: colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).mapPickerOutOfCoverage,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (state.status == MapPickerStatus.addressReady) {
      return Row(
        children: [
          Icon(Icons.location_on, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El sector arriba: es la referencia que va a escuchar el
                // conductor, así que el pasajero ve exactamente eso.
                if (state.sector != null)
                  Text(
                    state.sector!,
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  state.address ?? '',
                  style: TextStyle(
                    fontSize: state.sector != null ? 12 : 14,
                    color:
                        state.sector != null
                            ? onSurface.withValues(alpha: 0.6)
                            : onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Text(
      AppLocalizations.of(context).mapPickerHint,
      style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
    );
  }
}
