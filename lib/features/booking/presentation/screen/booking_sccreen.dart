import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/booking/presentation/component/booking_header.dart';
import 'package:passenger_app/features/booking/presentation/component/confirmation_dialog.dart';
import 'package:passenger_app/features/booking/presentation/component/location_denied.dart';
import 'package:passenger_app/shared/geolocator/location/location_bloc.dart';
import 'package:passenger_app/shared/presentation/component/custom_button.dart';
import 'package:passenger_app/shared/presentation/component/custom_loader.dart';
import '../bloc/location_search/location_search_bloc.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => GetIt.instance<LocationBloc>()),
        BlocProvider(create: (_) => GetIt.instance<LocationSearchBloc>()),
        BlocProvider(create: (_) => GetIt.instance<BookingBloc>()),
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

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
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
      backgroundColor: Colors.grey.shade50,
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
                                    TaxiConfirmationDialog.show(
                                      context: context,
                                      address: state.pickupAddress!,
                                      onConfirm: () {},
                                    );
                                  }
                                  : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLocationSection() {
    return BlocConsumer<LocationBloc, LocationState>(
      listenWhen: (previous, current) {
        return previous.lastKnownLocation != current.lastKnownLocation;
      },
      listener: (context, state) {
        if (state.lastKnownLocation != null) {
          context.read<BookingBloc>().add(
            FetchPickupAddress(
              latitude: state.lastKnownLocation!.latitude,
              longitude: state.lastKnownLocation!.longitude,
            ),
          );
        }
      },
      builder: (context, state) {
        return BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state.status == BookingStatus.fetchingAddress) {
              return Center(child: CustomLoader());
            }

            return Column(
              children: [
                _buildLocationCard(address: state.pickupAddress),

                const SizedBox(height: 24),

                _buildSearchBar(context),

                _buildSearchResults(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocationCard({String? address}) {
    return BlocConsumer<LocationBloc, LocationState>(
      listenWhen: (previous, current) {
        return (previous.permissionStatus != current.permissionStatus);
      },
      listener: (context, state) {
        final hasPermissions =
            (state.permissionStatus == LocationPermission.always ||
                state.permissionStatus == LocationPermission.whileInUse) &&
            !state.isCheckingLocation;

        if (hasPermissions) {
          context.read<LocationBloc>().add(FetchCurrentLocationEvent());
        }
      },

      builder: (context, state) {
        if (state.isCheckingLocation) {
          return const Center(
            child: Column(
              children: [CustomLoader(), Text('Comprobando permisos...')],
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

        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle, color: Colors.green, size: 20),
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
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<LocationSearchBloc>().add(
                  SearchQueryChanged(query: value),
                );
              },
              decoration: InputDecoration(
                hintText: "Buscar dirección o lugar...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                border: InputBorder.none,
                // The close icon is added here as a suffixIcon
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
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
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<LocationSearchBloc, LocationSearchState>(
      builder: (context, state) {
        if (state is LocationSearchInitial) {
          return const SizedBox.shrink();
        }

        if (state is LocationSearchLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Center(child: CircularProgressIndicator(color: Colors.pink)),
          );
        }

        if (state is LocationSearchError) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          );
        }

        if (state is LocationSearchLoaded) {
          if (state.places.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                "No se encontraron resultados",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.places.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final place = state.places[index];
                return ListTile(
                  leading: Icon(Icons.location_on, color: Colors.grey.shade400),
                  title: Text(
                    place.address,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  onTap: () {
                    context.read<BookingBloc>().add(
                      UpdatePickUpAddress(pickUpAddress: place.address),
                    );
                    context.read<LocationSearchBloc>().add(
                      ClearSearchResults(),
                    );

                    _searchController.clear();
                    FocusScope.of(context).unfocus();
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
