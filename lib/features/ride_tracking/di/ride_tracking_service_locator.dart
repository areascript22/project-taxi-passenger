import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/ride_tracking/data/repository/ride_tracking_repository_impl.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/features/ride_tracking/presentation/bloc/ride_tracking_bloc.dart';

void initRideTracking(GetIt sl) {
  sl.registerFactory<RideTrackingRepository>(
    () => RideTrackingRepositoryImpl(database: FirebaseDatabase.instance),
  );
  sl.registerLazySingleton(() => RideTrackingBloc(repository: sl<RideTrackingRepository>()));
}
