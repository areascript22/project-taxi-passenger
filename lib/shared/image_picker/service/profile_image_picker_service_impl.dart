import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/error/errors.dart';
import 'profile_image_picker_service.dart';

class ProfileImagePickerServiceImpl implements ProfileImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Either<Failure, File?>> pickImage({
    required ProfileImageSource source,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source:
            source == ProfileImageSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        return const Right(null);
      }

      return Right(File(picked.path));
    } catch (e) {
      debugPrint('ImagePickerDebug | Error en pickImage: $e');
      return Left(Failure(message: 'No se pudo obtener la imagen seleccionada'));
    }
  }
}
