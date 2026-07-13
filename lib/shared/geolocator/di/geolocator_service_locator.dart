import 'package:get_it/get_it.dart';
import 'package:passenger_app/shared/geolocator/location/location_bloc.dart';
import 'package:passenger_app/shared/geolocator/service/geolocator/geolocator_service.dart';
import 'package:passenger_app/shared/geolocator/service/geolocator/geolocator_service_impl.dart';

void initGeolocator(GetIt sl) {
  sl.registerFactory<GeolocatorService>(() => GeolocatorServiceServiceImpl());
  sl.registerFactory<LocationBloc>(()=> LocationBloc(locationService: sl<GeolocatorService>()));

}