import 'package:dio/dio.dart';

/// Adjunta el token de sesion (`Authorization: Bearer ...`) SOLO a las
/// peticiones dirigidas a nuestro servidor.
///
/// El cliente Dio es compartido y tambien llama a APIs de Google (Places,
/// Geocoding) con URL absolutas. Mandarles el ID token de Firebase como Bearer
/// hace que Google lo trate como credencial OAuth, no lo reconozca y rechace
/// la peticion con 401 aunque lleve la API key: el buscador de direcciones
/// dejo de encontrar nada por eso. El token de sesion tampoco debe salir hacia
/// terceros.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor({required this.tokenProvider});

  final Future<String?> Function() tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isOwnServer(options: options)) {
      final idToken = await tokenProvider();
      if (idToken != null) {
        options.headers['Authorization'] = 'Bearer $idToken';
      }
    }
    handler.next(options);
  }

  static bool _isOwnServer({required RequestOptions options}) {
    final serverHost = Uri.tryParse(options.baseUrl)?.host ?? '';
    return options.uri.host == serverHost;
  }
}
