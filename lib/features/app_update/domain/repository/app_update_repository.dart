import 'package:dartz/dartz.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/app_update/domain/entity/update_requirement_entity.dart';

abstract class AppUpdateRepository {
  /// Pregunta al servidor si la versión instalada todavía se admite.
  ///
  /// Es un endpoint público: funciona antes de iniciar sesión.
  Future<Either<Failure, UpdateRequirementEntity>> checkUpdate();
}
