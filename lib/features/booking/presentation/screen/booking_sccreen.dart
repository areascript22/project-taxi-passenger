import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/core/theme/app_colors.dart';
import 'package:passenger_app/features/booking/domain/entity/request_entity.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/booking/presentation/component/booking_header.dart';
import 'package:passenger_app/features/booking/presentation/component/confirmation_dialog.dart';
import 'package:passenger_app/features/booking/presentation/component/location_denied.dart';
import 'package:passenger_app/features/booking/presentation/component/waiting_for_driver_dialog.dart';
import 'package:passenger_app/features/ride_tracking/domain/entity/ride_entity.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import 'package:passenger_app/shared/geolocator/location/location_bloc.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import 'package:passenger_app/shared/presentation/component/custom_loader.dart';
import 'package:passenger_app/shared/presentation/failure_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/feedback/feedback_service.dart';
import '../bloc/location_search/location_search_bloc.dart';

class BookingScreen extends StatelessWidget {
  // Solicitud 'pending' recuperada al reabrir la app (ver SessionScreen):
  // si viene seteado, hay que resumir el diálogo "Buscando conductor" en
  // vez de mostrar la pantalla de booking normal.
  final RideEntity? recoveredRide;

  const BookingScreen({super.key, this.recoveredRide});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GetIt.instance<LocationBloc>()),
        BlocProvider(create: (_) => GetIt.instance<LocationSearchBloc>()),
        BlocProvider.value(value: GetIt.instance<BookingBloc>()),
      ],
      child: BookingView(recoveredRide: recoveredRide),
    );
  }
}

class BookingView extends StatefulWidget {
  final RideEntity? recoveredRide;

  const BookingView({super.key, this.recoveredRide});

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
    _maybeResumeWaitingDialog();
  }

  void _maybePlayWelcome() {
    if (_hasCheckedWelcomeThisSession) return;
    _hasCheckedWelcomeThisSession = true;

    // Si SessionScreen nos mandó acá con una solicitud 'pending' recuperada
    // (ver widget.recoveredRide), ya vamos a mostrar el diálogo "Buscando
    // conductor" -- no tiene sentido saludar de bienvenida encima.
    if (widget.recoveredRide != null) return;

    // El saludo se difiere al primer frame (igual que
    // _maybeResumeWaitingDialog) porque AppLocalizations es un
    // InheritedWidget: leerlo durante initState revienta con
    // "dependOnInheritedWidgetOfExactType called before initState completed".
    // Antes de la traducción esto era un string literal y no dependía del
    // árbol, así que la llamada directa funcionaba.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      GetIt.instance<FeedbackService>().announce(
        AppLocalizations.of(context).bookingWelcomeAnnouncement,
      );
    });
  }

  // Resume el diálogo "Buscando conductor" si SessionScreen detectó que el
  // pasajero tiene una solicitud 'pending' en Firebase (la app se cerró
  // antes de que un conductor aceptara). El countdown de
  // WaitingForDriverDialog usa el createdAt real de la solicitud, así que no
  // se reinicia desde cero.
  void _maybeResumeWaitingDialog() {
    final ride = widget.recoveredRide;
    if (ride == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final sessionState = context.read<SessionBloc>().state;
      if (sessionState is! SessionAuthenticated) return;

      GetIt.instance<RideTrackingBloc>().add(
        StartRideTracking(passengerId: sessionState.user.id),
      );

      WaitingForDriverDialog.show(
        context: context,
        onCancel: () {
          context.read<BookingBloc>().add(CancelTaxiRequest());
        },
        rideCreatedAtMillis: ride.createdAtMillis,
      );
    });
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
                          textButton: AppLocalizations.of(context).bookingRequestTaxi,
                          // canRequestTaxi incluye estar DENTRO de la zona de
                          // cobertura: fuera de los sectores de Riobamba el
                          // botón queda deshabilitado.
                          onTap:
                              state.canRequestTaxi
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
        // canRequestTaxi reemplaza al chequeo anterior, que usaba `||` donde
        // correspondía `&&`: con solo una de las tres cosas presente seguía de
        // largo y reventaba en los `!` de abajo.
        if (!state.canRequestTaxi) {
          return;
        }

        final request = RequestEntity(
          pickupLat: state.pickupLat!,
          pickupLng: state.pickupLng!,
          pickupAddress: state.pickupAddress!,
          pickupSector: state.pickupSector,
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
          return Center(
            child: Column(
              children: [
                const CustomLoader(),
                Text(AppLocalizations.of(context).bookingCheckingPermissions),
              ],
            ),
          );
        }

        if (state.locationProcess == LocationProcess.gettingCurrentCords) {
          return Center(
            child: Column(
              children: [
                const CustomLoader(),
                Text(AppLocalizations.of(context).bookingGettingLocation),
              ],
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
              return Center(
                child: Column(
                  children: [
                    const CustomLoader(),
                    Text(AppLocalizations.of(context).bookingGettingAddress),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildLocationCard(context, state: state),

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

  Widget _buildLocationCard(BuildContext context, {required BookingState state}) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final success = context.appColors.success;
    final isOutOfCoverage = state.isOutOfCoverage;
    // Fuera de cobertura la tarjeta se pinta con el rojo del tema: el pasajero
    // tiene que ver que ese punto no sirve antes de buscar el botón.
    final accent = isOutOfCoverage ? colorScheme.error : success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isOutOfCoverage
                  ? colorScheme.error.withValues(alpha: 0.3)
                  : onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [

          BlocBuilder<LocationSearchBloc, LocationSearchState>(
            builder: (context, searchState) {
              if(searchState is LocationSearchLoaded && searchState.searchLoadedProcess == SearchLoadedProcess.gettingCords){
                return CustomLoader();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOutOfCoverage ? Icons.location_off_rounded : Icons.circle,
                  color: accent,
                  size: 20,
                ),
              );
            },
          ),

          const SizedBox(width: 16),
          Expanded(
            child:
                isOutOfCoverage
                    ? _OutOfCoverageText(address: state.pickupAddress)
                    : _PickupText(
                      sector: state.pickupSector,
                      address: state.pickupAddress,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    // IntrinsicHeight + stretch: el botón de "elegir en el mapa" queda
    // como una tarjeta propia, del mismo alto que el buscador, en vez de un
    // ícono suelto adentro del campo de texto -- se distingue de una vez
    // como una acción alternativa a escribir, no como un simple adorno del
    // input.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    color: onSurface.withValues(alpha: 0.5),
                    size: 22,
                  ),
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
                        hintText: AppLocalizations.of(context).bookingSearchHint,
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MapPickerButton(onTap: () => _openMapPicker(context)),
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
              context.failureText(state.code),
              style: TextStyle(color: colorScheme.error, fontSize: 14),
            ),
          );
        }

        if (state is LocationSearchLoaded) {
          if (state.places.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                AppLocalizations.of(context).bookingNoResults,
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

// Tarjeta cuadrada tintada con el pin de marca en vez del IconButton
// genérico que había antes -- mismo alto que el buscador (ver
// IntrinsicHeight en _buildSearchBar) y un tap target de 56x56, bastante
// más fácil de acertar que el ícono de 24px que tenía antes.
class _MapPickerButton extends StatelessWidget {
  const _MapPickerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: AppLocalizations.of(context).bookingPickOnMap,
      child: Material(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/location.png',
              width: 28,
              height: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// El sector va arriba y en negrita porque es la referencia que el conductor va
// a escuchar; la dirección exacta queda como detalle debajo.
class _PickupText extends StatelessWidget {
  final String? sector;
  final String? address;

  const _PickupText({required this.sector, required this.address});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sector != null && sector!.isNotEmpty) ...[
          Text(
            sector!,
            style: TextStyle(
              fontSize: 14,
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          address ?? '',
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OutOfCoverageText extends StatelessWidget {
  final String? address;

  const _OutOfCoverageText({required this.address});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bookingOutOfCoverageTitle,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.bookingOutOfCoverageMessage,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.error.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        // Se sigue mostrando lo que eligió: sin esto, tocar una sugerencia
        // fuera de cobertura borra la pantalla sin decir qué fue rechazado.
        if (address != null && address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            address!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}
