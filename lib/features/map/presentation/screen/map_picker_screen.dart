import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import '../bloc/map_picker/map_picker_bloc.dart';

// Fallback center used when no prior pickup location is known yet,
// matching the autocomplete search bias in location_search_repository_impl.dart.
const double _fallbackLatitude = -1.6702;
const double _fallbackLongitude = -78.6631;

class MapPickerScreen extends StatelessWidget {
  final PlaceEntity? initialPlace;

  const MapPickerScreen({super.key, this.initialPlace});

  @override
  Widget build(BuildContext context) {
    final initialLatitude = initialPlace?.latitude ?? _fallbackLatitude;
    final initialLongitude = initialPlace?.longitude ?? _fallbackLongitude;

    return BlocProvider(
      create: (_) => GetIt.instance<MapPickerBloc>()
        ..add(
          MapCenterInitialized(
            latitude: initialLatitude,
            longitude: initialLongitude,
          ),
        ),
      child: MapPickerView(
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
    );
  }
}

class MapPickerView extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapPickerView({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  GoogleMapController? _mapController;
  late double _pendingLatitude;
  late double _pendingLongitude;

  @override
  void initState() {
    super.initState();
    _pendingLatitude = widget.initialLatitude;
    _pendingLongitude = widget.initialLongitude;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraIdle() {
    context.read<MapPickerBloc>().add(
      MapCameraIdle(latitude: _pendingLatitude, longitude: _pendingLongitude),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu ubicación'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialLatitude, widget.initialLongitude),
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _pendingLatitude = position.target.latitude;
              _pendingLongitude = position.target.longitude;
            },
            onCameraIdle: _onCameraIdle,
            zoomControlsEnabled: false,
          ),

          IgnorePointer(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: colorScheme.primary,
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
                          textButton: 'Confirmar ubicación',
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
            'Buscando dirección...',
            style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
          ),
        ],
      );
    }

    if (state.status == MapPickerStatus.error) {
      return Text(
        state.errorMessage ?? 'No se pudo obtener la dirección.',
        style: TextStyle(fontSize: 14, color: colorScheme.error),
      );
    }

    if (state.status == MapPickerStatus.addressReady) {
      return Row(
        children: [
          Icon(Icons.location_on, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.address ?? '',
              style: TextStyle(
                fontSize: 14,
                color: onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      'Mueve el mapa para elegir tu ubicación',
      style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.5)),
    );
  }
}
