import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/core/error/errors.dart';
import 'package:passenger_app/features/app_update/domain/service/store_launcher_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreLauncherServiceImpl implements StoreLauncherService {
  @override
  Future<Either<Failure, Unit>> open({required String url}) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        debugPrint('AppUpdateDebug | URL de tienda inválida: "$url"');
        return Left(Failure(code: FailureCode.storeOpenFailed));
      }

      // externalApplication: abre Play Store (o el navegador), no una vista
      // embebida dentro de la app.
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('AppUpdateDebug | El sistema no pudo abrir "$url"');
        return Left(Failure(code: FailureCode.storeOpenFailed));
      }
      return const Right(unit);
    } catch (e) {
      debugPrint('AppUpdateDebug | Error al abrir la tienda: $e');
      return Left(Failure(code: FailureCode.storeOpenFailed));
    }
  }
}
