import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dotenv_service.dart';

class DotEnvServiceImpl implements DotEnvService {

  @override
  Future<void> initialize() async {
    const String envFile = String.fromEnvironment(
      'ENV_FILE',
      defaultValue: 'assets/env/.env_dev',
    );

    await dotenv.load(fileName: envFile);
  }

  @override
  String get(String key) {
    return dotenv.env[key] ?? '';
  }
}