part of 'location_search_bloc.dart';

@immutable
sealed class LocationSearchEvent {}

final class SearchQueryChanged extends LocationSearchEvent {
  final String query;

  SearchQueryChanged({required this.query});
}

final class ClearSearchResults extends LocationSearchEvent {}

final class FetchCordsPlace extends LocationSearchEvent {
  final String placeId;

  FetchCordsPlace({required this.placeId});
}
