import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/booking/data/repository/booking_repository_impl.dart';
import 'package:passenger_app/features/booking/data/repository/location_search_repository_impl.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import 'package:passenger_app/features/booking/domain/repository/location_search_repository.dart';
import 'package:passenger_app/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/features/booking/presentation/bloc/location_search/location_search_bloc.dart';
import 'package:passenger_app/shared/geocoding/domain/repository/geocoding_repository.dart';

void initBooking(GetIt sl) {
  sl.registerFactory<LocationSearchRepository>(
    () => LocationSearchRepositoryImpl(),
  );
  sl.registerFactory<BookingRepository>(
    () => BookingRepositoryImpl(database: FirebaseDatabase.instance),
  );

  sl.registerFactory(
    () => LocationSearchBloc(
      locationSearchRepository: sl<LocationSearchRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => BookingBloc(
      geocodingRepository: sl<GeocodingRepository>(),
      bookingRepository: sl<BookingRepository>(),
    ),
  );
}
