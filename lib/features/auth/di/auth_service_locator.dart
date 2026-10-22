import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:passenger_app/features/auth/domain/repository/auth_repository.dart';
import 'package:passenger_app/features/auth/presentation/bloc/auth_bloc.dart';

void initAuthDI(GetIt sl) {
  sl.registerFactory<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerFactory(() => AuthBloc(authRepository: sl<AuthRepository>()));
}
