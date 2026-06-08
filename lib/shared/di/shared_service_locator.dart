import 'package:get_it/get_it.dart';
import 'package:passenger_app/shared/data/repository/session_repository_impl.dart';
import 'package:passenger_app/shared/domain/repository/session_repository.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';

void initSharedDI(GetIt sl) {
  sl.registerFactory<SessionRepository>(() => SessionRepositoryImpl());
  sl.registerLazySingleton(
    () => SessionBloc(sessionRepository: sl<SessionRepository>()),
  );
}
