part of 'location_search_bloc.dart';

enum SearchLoadedProcess {
  initial,
  gettingCords,
  gettingCordsError,
  gettingCordsReady,
}

@immutable
sealed class LocationSearchState {}

final class LocationSearchInitial extends LocationSearchState {}

final class LocationSearchLoading extends LocationSearchState {}

final class LocationSearchError extends LocationSearchState {
  final String message;

  LocationSearchError({required this.message});
}

final class LocationSearchLoaded extends LocationSearchState {
  final List<PlaceEntity> places;
  final PlaceEntity? placeWithCords;
  final SearchLoadedProcess searchLoadedProcess;
  final String? cordsError;

  LocationSearchLoaded({
    required this.places,
    this.placeWithCords,
    this.searchLoadedProcess = SearchLoadedProcess.initial,
    this.cordsError,
  });

  LocationSearchLoaded copyWith({
    List<PlaceEntity>? places,
    PlaceEntity? placeWithCords,
    SearchLoadedProcess? searchLoadedProcess,
    String? cordsError,
  }) {
    return LocationSearchLoaded(
      places: places ?? this.places,
      placeWithCords: placeWithCords ?? this.placeWithCords,
      searchLoadedProcess: searchLoadedProcess ?? this.searchLoadedProcess,
      cordsError: cordsError ?? this.cordsError,
    );
  }
}
