import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/ride_tracking/domain/repository/ride_tracking_repository.dart';
import 'package:passenger_app/shared/data/repository/session_repository_impl.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';

void initSharedDI(GetIt sl) {
  sl.registerFactory<SessionRepository>(() => SessionRepositoryImpl());
  sl.registerLazySingleton(
    () => SessionBloc(
      sessionRepository: sl<SessionRepository>(),
      // RideTrackingRepository se registra en initRideTracking, que corre
      // después -- no es un problema porque este closure solo se ejecuta la
      // primera vez que alguien pide SessionBloc (bien después de que
      // termina el arranque).
      rideTrackingRepository: sl<RideTrackingRepository>(),
    ),
  );
}
