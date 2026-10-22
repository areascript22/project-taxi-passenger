import 'package:get_it/get_it.dart';
import '../data/repository/geocoding_repository_impl.dart';
import '../domain/repository/geocoding_repository.dart';

void initGeocodingDI(GetIt sl) {
  sl.registerFactory<GeocodingRepository>(() => GeocodingRepositoryImpl());
}
