import 'package:get_it/get_it.dart';
import '../data/repository/chat_repository_impl.dart';
import '../domain/repository/chat_repository.dart';
import '../presentation/bloc/chat_bloc.dart';

void initChatDI(GetIt sl) {
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
  // Singleton (no factory): RideTrackingScreen arranca WatchMessages y
  // necesita seguir recibiendo mensajes (para el badge de no-leídos) aunque
  // ChatScreen no esté montado -- misma razón que RideTrackingBloc.
  sl.registerLazySingleton(() => ChatBloc(repository: sl<ChatRepository>()));
}
