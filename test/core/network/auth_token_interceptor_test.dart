import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:passenger_app/core/network/auth_token_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

// Adaptador que no sale a la red: guarda la peticion que habria enviado.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late Dio dio;
  var tokenCalls = 0;
  String? token;

  setUp(() {
    tokenCalls = 0;
    token = 'firebase-id-token';
    adapter = _CapturingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.taxigo.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthTokenInterceptor(
          tokenProvider: () async {
            tokenCalls++;
            return token;
          },
        ),
      );
  });

  test('adds the Bearer token to requests for our own server', () async {
    await dio.get('/api/me');

    expect(adapter.last!.headers['Authorization'], 'Bearer firebase-id-token');
  });

  test('adds it to absolute URLs on our own host too', () async {
    await dio.get('https://api.taxigo.test/api/me');

    expect(adapter.last!.headers['Authorization'], 'Bearer firebase-id-token');
  });

  test('does NOT send the token to Google APIs (Places / Geocoding)', () async {
    await dio.post('https://places.googleapis.com/v1/places:autocomplete');
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);

    await dio.get('https://maps.googleapis.com/maps/api/geocode/json');
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);

    expect(tokenCalls, 0);
  });

  test('sends no header when there is no signed-in user', () async {
    token = null;

    await dio.get('/api/me');

    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
  });
}
