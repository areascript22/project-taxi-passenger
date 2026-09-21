import 'package:get_it/get_it.dart';
import '../service/chat_presence_tracker.dart';

void initChatPresenceDI(GetIt sl) {
  sl.registerLazySingleton<ChatPresenceTracker>(() => ChatPresenceTracker());
}
