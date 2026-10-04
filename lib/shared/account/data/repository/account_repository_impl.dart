import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/core/network/dio_client.dart';
import 'package:passenger_app/shared/account/domain/repository/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  // Dio inyectable (default DioClient.instance) para poder mockearlo en
  // tests con mocktail -- los demás repositorios de la app usan el
  // singleton directo porque todavía no tienen test a nivel repositorio.
  AccountRepositoryImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  // El receiveTimeout global de DioClient (5s) está pensado para lecturas
  // normales y es demasiado corto para este endpoint: el borrado hace ~10
  // round trips a Firebase (Realtime DB, queries de chats + subcolección de
  // mensajes, Storage y Firestore) antes de responder, así que se pasa de 5s
  // siempre -- no es un caso de borde de red lenta. Con el timeout por
  // defecto, Dio abortaba la espera mientras el server seguía borrando, el
  // RetryInterceptor reintentaba, y el reintento chocaba con un usuario de
  // Auth ya eliminado (500) -> la app mostraba error sobre una cuenta que sí
  // se había borrado.
  //
  // Se sube solo en esta llamada, no en DioClient: subir el default haría que
  // cualquier request caído tardara 30s en avisar en vez de 5. Los retries se
  // mantienen (sirven contra red inestable) y ahora son seguros, porque
  // AccountService trata USER_NOT_FOUND como éxito.
  static const _deleteTimeout = Duration(seconds: 30);

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      await _dio.delete(
        '/api/account',
        options: Options(receiveTimeout: _deleteTimeout),
      );
      return const Right(unit);
    } on DioException catch (e) {
      debugPrint('AccountDebug | Error en deleteAccount: $e');
      if (e.response?.statusCode == 409) {
        return Left(
          Failure(code: FailureCode.accountHasActiveRide),
        );
      }
      return Left(
        Failure(code: FailureCode.accountDeleteFailed),
      );
    } catch (e) {
      debugPrint('AccountDebug | Error inesperado en deleteAccount: $e');
      return Left(
        Failure(code: FailureCode.accountDeleteFailed),
      );
    }
  }
}
