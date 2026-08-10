import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/booking/presentation/component/booking_header.dart';
import 'package:passenger_app/features/booking/presentation/component/confirmation_dialog.dart';
import 'package:passenger_app/features/booking/presentation/component/location_denied.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/geolocator/location/location_bloc.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import 'package:passenger_app/shared/presentation/component/custom_loader.dart';
import '../../../../shared/feedback/feedback_service.dart';
import '../bloc/location_search/location_search_bloc.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GetIt.instance<LocationBloc>()),
        BlocProvider(create: (_) => GetIt.instance<LocationSearchBloc>()),
        BlocProvider.value(value: GetIt.instance<BookingBloc>()),
      ],
      child: const BookingView(),
    );
  }
}

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  final TextEditingController _searchController = TextEditingController();

  // static (no de instancia): sigue viva mientras el proceso de la app siga
  // vivo, sin importar cuántas veces se entre/salga de esta pantalla por
  // navegación interna (context.go). Se reinicia solo con un kill real de
  // la app -- que es justo cuando SÍ queremos poder volver a evaluar si
  // corresponde saludar de nuevo.
  static bool _hasCheckedWelcomeThisSession = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _maybePlayWelcome();
  }

  void _maybePlayWelcome() {
    if (_hasCheckedWelcomeThisSession) return;
    _hasCheckedWelcomeThisSession = true;

    // No hace falta chequear viaje en curso acá: si lo hubiera, SessionScreen
    // ya nos habría mandado directo a RideTrackingScreen en vez de acá (ver
    // shared/presentation/bloc/session/session_bloc.dart) -- si llegamos a
    // montar esta pantalla, es porque no hay ninguno.
    GetIt.instance<FeedbackService>().announce('Bienvenido a Via Go');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkLocationPermissions() {
    context.read<LocationBloc>().add(CheckAndRequestPermissionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BookingHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    _buildMainLocationSection(),

                    const SizedBox(height: 52),

                    BlocBuilder<BookingBloc, BookingState>(
                      builder: (context, state) {
                        return CustomButton(
                          textButton: "Solicitar taxi",
                          onTap:
                              state.pickupAddress != null
                                  ? () {
                                    _onRequestTaxi(state);
                                  }
                                  : null,
                        );
                      },
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onRequestTaxi(BookingState state) {
    TaxiConfirmationDialog.show(
      context: context,
      address: state.pickupAddress!,
      onConfirm: () {
        final isPickUpReady =
            state.pickupLng != null ||
            state.pickupLat != null ||
            state.pickupAddress != null;
        if (!isPickUpReady) {
          return;
        }

        final currentSessionState = context.read<SessionBloc>().state;
        if (currentSessionState is! SessionAuthenticated) {
          return;
        }

        final user = currentSessionState.user;

        final request = RequestEntity(
          pickupLat: state.pickupLat!,
          pickupLng: state.pickupLng!,
          pickupAddress: state.pickupAddress!,
          userId: user.id,
          userName: user.displayName ?? "user",
          userProfileImage: user.photoUrl ?? "n/a",
        );
        context.read<BookingBloc>().add(RequestTaxi(request: request));
      },
    );
  }

  Widget _buildMainLocationSection() {
    return BlocConsumer<LocationBloc, LocationState>(
      listenWhen: (previous, current) {
        final shouldListen =
            (previous.permissionStatus != current.permissionStatus) ||
            (previous.locationProcess != current.locationProcess);
        return shouldListen;
      },
      listener: (context, state) {
        final shouldFetchCords =
            (state.permissionStatus == LocationPermission.always ||
                state.permissionStatus == LocationPermission.whileInUse) &&
            state.locationProcess == LocationProcess.permissionsReady;

        if (shouldFetchCords) {
          context.read<LocationBloc>().add(FetchCurrentLocationEvent());
        }

        final shouldFetchAddress =
            state.locationProcess == LocationProcess.currentCordsReady &&
            state.lastKnownLocation != null;

        if (shouldFetchAddress) {
          context.read<BookingBloc>().add(
            FetchPickupAddress(
              latitude: state.lastKnownLocation!.latitude,
              longitude: state.lastKnownLocation!.longitude,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.locationProcess == LocationProcess.checkingPermissions) {
          return const Center(
            child: Column(
              children: [CustomLoader(), Text('Comprobando permisos...')],
            ),
          );
        }

        if (state.locationProcess == LocationProcess.gettingCurrentCords) {
          return const Center(
            child: Column(
              children: [CustomLoader(), Text('Ubteniendo tu ubicacion...')],
            ),
          );
        }

        if (state.permissionStatus == LocationPermission.denied ||
            state.permissionStatus == LocationPermission.deniedForever) {
          return LocationDenied(
            isPermanentlyDenied: true,
            onEnablePermissionsTapped: () {
              if (state.permissionStatus == LocationPermission.deniedForever) {
                context.read<LocationBloc>().add(OpenAppSettingsEvent());
                return;
              }

              context.read<LocationBloc>().add(
                CheckAndRequestPermissionEvent(),
              );
            },
          );
        }

        return BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state.status == BookingStatus.fetchingAddress) {
              return const Center(
                child: Column(
                  children: [
                    CustomLoader(),
                    Text('Ubteniendo tu direccion...'),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildLocationCard(context, address: state.pickupAddress),

                const SizedBox(height: 24),

                _buildSearchBar(context),

                _buildSearchResults(context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocationCard(BuildContext context, {String? address}) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final success = context.appColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [

          BlocBuilder<LocationSearchBloc, LocationSearchState>(
            builder: (context, state) {
              if(state is LocationSearchLoaded && state.searchLoadedProcess == SearchLoadedProcess.gettingCords){
                return CustomLoader();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.circle, color: success, size: 20),
              );
            },
          ),

          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: onSurface.withValues(alpha: 0.5), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: onSurface),
              onChanged: (value) {
                context.read<LocationSearchBloc>().add(
                  SearchQueryChanged(query: value),
                );
              },
              decoration: InputDecoration(
                hintText: "Buscar dirección o lugar...",
                hintStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                // The close icon is added here as a suffixIcon
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();

                    context.read<LocationSearchBloc>().add(
                      ClearSearchResults(),
                    );

                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.map_outlined, color: colorScheme.primary, size: 24),
            tooltip: 'Elegir en el mapa',
            onPressed: () => _openMapPicker(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final bookingState = context.read<BookingBloc>().state;

    final result = await context.push<PlaceEntity>(
      mapPickerRoute.route,
      extra: bookingState.pickupLat != null && bookingState.pickupLng != null
          ? PlaceEntity(
              address: bookingState.pickupAddress ?? '',
              latitude: bookingState.pickupLat,
              longitude: bookingState.pickupLng,
            )
          : null,
    );

    if (result == null || !mounted) return;

    context.read<BookingBloc>().add(UpdatePickUpAddress(placeEntity: result));
    _setSearchText(result.address);
  }

  void _setSearchText(String address) {
    _searchController.text = address;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return BlocConsumer<LocationSearchBloc, LocationSearchState>(
      listener: (context, state) {
        if (state is LocationSearchLoaded) {
          final cordsReady =
              state.searchLoadedProcess ==
                  SearchLoadedProcess.gettingCordsReady &&
              state.placeWithCords != null;
          if (cordsReady) {
            context.read<BookingBloc>().add(
              UpdatePickUpAddress(placeEntity: state.placeWithCords!),
            );
            context.read<LocationSearchBloc>().add(ClearSearchResults());

            _setSearchText(state.placeWithCords!.address);
            FocusScope.of(context).unfocus();
          }
        }
      },
      builder: (context, state) {
        if (state is LocationSearchInitial) {
          return const SizedBox.shrink();
        }

        if (state is LocationSearchLoading) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (state is LocationSearchError) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              state.message,
              style: TextStyle(color: colorScheme.error, fontSize: 14),
            ),
          );
        }

        if (state is LocationSearchLoaded) {
          if (state.places.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                "No se encontraron resultados",
                style: TextStyle(color: onSurface.withValues(alpha: 0.5)),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurface.withValues(alpha: 0.08)),
            ),

            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.places.length,
              separatorBuilder:
                  (context, index) => Divider(
                    color: onSurface.withValues(alpha: 0.06),
                    height: 1,
                  ),
              itemBuilder: (context, index) {
                final place = state.places[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: onSurface.withValues(alpha: 0.4),
                  ),
                  title: Text(
                    place.address,
                    style: TextStyle(fontSize: 14, color: onSurface),
                  ),
                  onTap: () {
                    context.read<LocationSearchBloc>().add(
                      FetchCordsPlace(placeId: place.placeId!),
                    );
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
