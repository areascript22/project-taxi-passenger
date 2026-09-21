import 'package:get_it/get_it.dart';
import '../../chat_presence/service/chat_presence_tracker.dart';
import '../service/push_notifications_service.dart';
import '../service/push_notifications_service_impl.dart';

void initPushNotificationsDI(GetIt sl) {
  sl.registerLazySingleton<PushNotificationsService>(
    () => PushNotificationsServiceImpl(
      chatPresenceTracker: sl<ChatPresenceTracker>(),
    ),
  );
}
