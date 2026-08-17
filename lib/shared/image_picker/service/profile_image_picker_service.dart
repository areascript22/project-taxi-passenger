import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../core/error/errors.dart';

enum ProfileImageSource { camera, gallery }

abstract class ProfileImagePickerService {
  // Devuelve null (dentro de Right) si el usuario cancela la selección.
  Future<Either<Failure, File?>> pickImage({required ProfileImageSource source});
}
