import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/map/presentation/bloc/map_picker/map_picker_bloc.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';

void initMap(GetIt sl) {
  sl.registerFactory(
    () => MapPickerBloc(geocodingRepository: sl<GeocodingRepository>()),
  );
}
