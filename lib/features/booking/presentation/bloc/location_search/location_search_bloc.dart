import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:passenger_app/features/booking/domain/entity/place_entity.dart';
import 'package:passenger_app/features/booking/domain/repository/location_search_repository.dart';
import 'package:passenger_app/features/booking/presentation/utils/debouncer.dart';

part 'location_search_event.dart';

part 'location_search_state.dart';

class LocationSearchBloc
    extends Bloc<LocationSearchEvent, LocationSearchState> {
  final LocationSearchRepository locationSearchRepository;

  LocationSearchBloc({required this.locationSearchRepository})
    : super(LocationSearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );

    on<ClearSearchResults>((event, emit) {
      emit(LocationSearchInitial());
    });

  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<LocationSearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(LocationSearchInitial());
      return;
    }

    emit(LocationSearchLoading());

    final results = await locationSearchRepository.getAutocompletePlaces(
      query: event.query,
    );

    results.fold(
      (l) => emit(LocationSearchError(message: l.message)),
      (places) => emit(LocationSearchLoaded(places: places)),
    );
  }
}
