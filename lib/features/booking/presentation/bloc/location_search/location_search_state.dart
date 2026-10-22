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
  final FailureCode code;

  LocationSearchError({required this.code});
}

final class LocationSearchLoaded extends LocationSearchState {
  final List<PlaceEntity> places;
  final PlaceEntity? placeWithCords;
  final SearchLoadedProcess searchLoadedProcess;
  final FailureCode? cordsErrorCode;

  LocationSearchLoaded({
    required this.places,
    this.placeWithCords,
    this.searchLoadedProcess = SearchLoadedProcess.initial,
    this.cordsErrorCode,
  });

  LocationSearchLoaded copyWith({
    List<PlaceEntity>? places,
    PlaceEntity? placeWithCords,
    SearchLoadedProcess? searchLoadedProcess,
    FailureCode? cordsErrorCode,
  }) {
    return LocationSearchLoaded(
      places: places ?? this.places,
      placeWithCords: placeWithCords ?? this.placeWithCords,
      searchLoadedProcess: searchLoadedProcess ?? this.searchLoadedProcess,
      cordsErrorCode: cordsErrorCode ?? this.cordsErrorCode,
    );
  }
}
