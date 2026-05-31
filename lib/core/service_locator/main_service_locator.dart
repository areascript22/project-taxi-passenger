import 'package:get_it/get_it.dart';
import 'package:passenger_app/features/auth/di/auth_service_locator.dart';
import 'package:passenger_app/shared/services/dotenv/dotenv_service_locator.dart';

final GetIt mainServiceLocator = GetIt.instance;

Future<void> initMainServiceLocator() async {
  initDotEnvDI(mainServiceLocator);
  initAuthDI(mainServiceLocator);
}
