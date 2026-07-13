part of 'location_search_bloc.dart';

@immutable
sealed class LocationSearchState {}

final class LocationSearchInitial extends LocationSearchState {}
final class LocationSearchLoading extends LocationSearchState {}
final class LocationSearchLoaded extends LocationSearchState {
  final List<PlaceEntity> places;

  LocationSearchLoaded({required this.places});
}
final class LocationSearchError extends LocationSearchState {
  final String message;

  LocationSearchError({required this.message});

}

