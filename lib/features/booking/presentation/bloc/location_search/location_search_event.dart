part of 'location_search_bloc.dart';

@immutable
sealed class LocationSearchEvent {}

final class SearchQueryChanged extends LocationSearchEvent{
  final String query;
  SearchQueryChanged({required this.query});
}
final class ClearSearchResults extends LocationSearchEvent {}