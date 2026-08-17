import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/passenger_entity.dart';
import '../../domain/repository/passenger_profile_repository.dart';
import '../model/passenger_model.dart';

class PassengerProfileRepositoryImpl implements PassengerProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _passengersCollection = 'passengers';

  @override
  Future<Either<Failure, PassengerEntity?>> getPassenger({
    required String passengerId,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection(_passengersCollection)
              .doc(passengerId)
              .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return const Right(null);
      }

      final passenger = PassengerModel.fromJson(
        snapshot.data()!,
        id: snapshot.id,
      );
      return Right(passenger.toEntity());
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en getPassenger: $e');
      return Left(
        Failure(message: 'No se pudo verificar tu información de pasajero'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> registerPassenger({
    required PassengerEntity passenger,
    File? profileImage,
  }) async {
    try {
      String? photoUrl = passenger.photoUrl;

      if (profileImage != null) {
        final storageRef = _storage.ref(
          'passenger_profile_photos/${passenger.id}.jpg',
        );
        await storageRef.putFile(profileImage);
        photoUrl = await storageRef.getDownloadURL();
      }

      final passengerToSave = passenger.copyWith(photoUrl: photoUrl);

      final passengerRef = _firestore
          .collection(_passengersCollection)
          .doc(passenger.id);

      await passengerRef.set({
        ...PassengerModel.fromEntity(passengerToSave).toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return const Right(unit);
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en registerPassenger: $e');
      return Left(
        Failure(
          message: 'No se pudo guardar tu información. Intenta nuevamente.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PassengerEntity>> updatePassenger({
    required PassengerEntity passenger,
    File? profileImage,
  }) async {
    try {
      String? photoUrl = passenger.photoUrl;

      if (profileImage != null) {
        final storageRef = _storage.ref(
          'passenger_profile_photos/${passenger.id}.jpg',
        );
        await storageRef.putFile(profileImage);
        photoUrl = await storageRef.getDownloadURL();
      }

      final passengerToSave = passenger.copyWith(photoUrl: photoUrl);

      final passengerRef = _firestore
          .collection(_passengersCollection)
          .doc(passenger.id);

      await passengerRef.update({
        'firstName': passengerToSave.firstName,
        'lastName': passengerToSave.lastName,
        'photoUrl': passengerToSave.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Right(passengerToSave);
    } catch (e) {
      debugPrint('PassengerProfileDebug | Error en updatePassenger: $e');
      return Left(
        Failure(
          message: 'No se pudo actualizar tu información. Intenta nuevamente.',
        ),
      );
    }
  }
}
