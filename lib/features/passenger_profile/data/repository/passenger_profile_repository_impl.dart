import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entity/passenger_entity.dart';
import '../../domain/repository/passenger_profile_repository.dart';
import '../model/passenger_model.dart';

/// Sube [file] a [path] en Storage y devuelve su URL de descarga.
typedef ProfilePhotoUploader = Future<String> Function({
  required String path,
  required File file,
});

// El perfil vive en Postgres y se lee/escribe por el servidor: GET /api/me lo
// devuelve y PUT /api/me/passenger-profile lo crea o actualiza (idempotente).
// Lo unico que la app sigue haciendo directo es subir la foto a Storage
// (reglas por uid) y mandarle la URL al servidor.
class PassengerProfileRepositoryImpl implements PassengerProfileRepository {
  /// [dio] y [photoUploader] son inyectables para probar sin red ni Firebase;
  /// sin ellos se usan DioClient.instance y Firebase Storage.
  PassengerProfileRepositoryImpl({Dio? dio, ProfilePhotoUploader? photoUploader})
    : _injectedDio = dio,
      _photoUploader = photoUploader ?? _uploadToStorage;

  final Dio? _injectedDio;
  final ProfilePhotoUploader _photoUploader;

  // Lazy a proposito: el repositorio se debe poder construir (y probar) sin
  // inicializar dotenv ni Firebase.
  late final Dio _dio = _injectedDio ?? DioClient.instance;

  static Future<String> _uploadToStorage({
    required String path,
    required File file,
  }) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  @override
  Future<Either<Failure, PassengerEntity?>> getPassenger({
    required String passengerId,
  }) async {
    try {
      final response = await _dio.get('/api/me');
      final me = Map<String, dynamic>.from(response.data as Map);
      return Right(PassengerModel.fromMe(me)?.toEntity());
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en getPassenger: $e');
      return Left(
        Failure(code: FailureCode.passengerProfileCheckFailed),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> registerPassenger({
    required PassengerEntity passenger,
    File? profileImage,
  }) async {
    try {
      await _saveProfile(passenger: passenger, profileImage: profileImage);
      return const Right(unit);
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en registerPassenger: $e');
      return Left(
        Failure(code: FailureCode.profileSaveFailed),
      );
    }
  }

  @override
  Future<Either<Failure, PassengerEntity>> updatePassenger({
    required PassengerEntity passenger,
    File? profileImage,
  }) async {
    try {
      final photoUrl = await _saveProfile(
        passenger: passenger,
        profileImage: profileImage,
      );
      return Right(passenger.copyWith(photoUrl: photoUrl));
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en updatePassenger: $e');
      return Left(
        Failure(code: FailureCode.profileUpdateFailed),
      );
    }
  }

  // Alta y edicion usan el mismo endpoint. Devuelve la URL de la foto que
  // quedo guardada (null si no hay).
  Future<String?> _saveProfile({
    required PassengerEntity passenger,
    File? profileImage,
  }) async {
    String? photoUrl = passenger.photoUrl;

    if (profileImage != null) {
      photoUrl = await _photoUploader(
        path: 'passenger_profile_photos/${passenger.id}.jpg',
        file: profileImage,
      );
    }

    await _dio.put(
      '/api/me/passenger-profile',
      data: {
        'firstName': passenger.firstName,
        'lastName': passenger.lastName,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      },
      options: Options()..disableRetry = true,
    );
    return photoUrl;
  }

  // El token de notificaciones y el idioma ya no se escriben directo en
  // Firestore: van al servidor (PUT /api/me/device), que sabe de que persona
  // y de que app son por el token de sesion. `passengerId` se conserva en la
  // firma por compatibilidad con los llamadores, pero el servidor NO lo usa:
  // la identidad sale siempre del token.
  @override
  Future<Either<Failure, Unit>> updateFcmToken({
    required String passengerId,
    required String token,
    required String language,
  }) async {
    try {
      await _dio.put(
        '/api/me/device',
        data: {'app': 'passenger', 'fcmToken': token, 'language': language},
      );
      return const Right(unit);
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en updateFcmToken: $e');
      return Left(
        Failure(code: FailureCode.fcmTokenSaveFailed),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> updateLanguage({
    required String passengerId,
    required String language,
  }) async {
    try {
      await _dio.put(
        '/api/me/device',
        data: {'app': 'passenger', 'language': language},
      );
      return const Right(unit);
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en updateLanguage: $e');
      return Left(
        Failure(code: FailureCode.pushLanguageSaveFailed),
      );
    }
  }
}
