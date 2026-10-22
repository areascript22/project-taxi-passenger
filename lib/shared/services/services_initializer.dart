import 'package:passenger_app/core/service_locator/main_service_locator.dart';
import 'package:passenger_app/shared/services/dotenv/dotenv_service.dart';

class ServicesInitializer{
  static Future<void> initializeServices() async {
    await mainServiceLocator<DotEnvService>().initialize();
  }
}