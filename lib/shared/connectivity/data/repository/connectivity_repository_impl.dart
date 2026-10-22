import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../domain/repository/connectivity_repository.dart';

// Hostname liviano solo para confirmar que hay salida real a internet (DNS
// + socket), no para ningún otro propósito. No se usa ningún endpoint propio
// del proyecto a propósito: si el backend está caído pero el resto de
// internet funciona, el banner de "sin conexión" no debería encenderse por
// eso (ese es un problema del servidor, no del dispositivo).
const _probeHost = 'google.com';
const _probeTimeout = Duration(seconds: 5);

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  // connectivity y hasInternetAccessOverride son inyectables para poder
  // testear esta clase con mocktail sin depender del plugin real ni de una
  // conexión de red de verdad -- ver connectivity_repository_impl_test.dart.
  ConnectivityRepositoryImpl({
    Connectivity? connectivity,
    Future<bool> Function()? hasInternetAccessOverride,
  }) : _connectivity = connectivity ?? Connectivity(),
       _hasInternetAccessOverride = hasInternetAccessOverride;

  final Connectivity _connectivity;
  final Future<bool> Function()? _hasInternetAccessOverride;

  @override
  Stream<bool> watchConnection() async* {
    try {
      yield await _resolveStatus(await _connectivity.checkConnectivity());
    } catch (e) {
      debugPrint('ConnectivityDebug | Error en checkConnectivity inicial: $e');
      yield false;
    }

    yield* _connectivity.onConnectivityChanged
        .asyncMap((results) async {
          try {
            return await _resolveStatus(results);
          } catch (e) {
            debugPrint(
              'ConnectivityDebug | Error resolviendo un cambio de '
              'conectividad: $e',
            );
            return false;
          }
        })
        .distinct();
  }

  // Traducir List<ConnectivityResult> a un booleano no es suficiente por sí
  // solo: el dispositivo puede estar "conectado" a un wifi sin internet real
  // (portal cautivo, router sin salida, etc.), así que sobre una interfaz
  // activa siempre se confirma con una resolución DNS real.
  Future<bool> _resolveStatus(List<ConnectivityResult> results) async {
    if (results.every((result) => result == ConnectivityResult.none)) {
      return false;
    }
    return _hasInternetAccess();
  }

  Future<bool> _hasInternetAccess() async {
    if (_hasInternetAccessOverride != null) {
      return _hasInternetAccessOverride();
    }

    try {
      final lookup = await InternetAddress.lookup(
        _probeHost,
      ).timeout(_probeTimeout);
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      debugPrint(
        'ConnectivityDebug | Sin acceso real a internet (SocketException): $e',
      );
      return false;
    } on TimeoutException catch (e) {
      debugPrint(
        'ConnectivityDebug | Timeout verificando acceso real a internet: $e',
      );
      return false;
    } catch (e) {
      debugPrint(
        'ConnectivityDebug | Error inesperado verificando acceso a internet: $e',
      );
      return false;
    }
  }
}
