abstract class DotEnvService {
  Future<void> initialize();

  String get(String key);
}