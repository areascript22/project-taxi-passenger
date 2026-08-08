import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passenger_app/core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repository/geocoding_repository.dart';

class GeocodingRepositoryImpl implements GeocodingRepository {
  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double lat,
    required double lng,
  }) async {
    final apiKey = dotenv.env['GEOCODING_API'];

    if (apiKey == null || apiKey.isEmpty) {
      return Left(Failure(message: 'Error interno: API Key no configurada.'));
    }

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=es';

    try {
      final response = await DioClient.instance.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final String formattedAddress =
              data['results'][0]['formatted_address'];
          return Right(formattedAddress);
        } else {
          return Left(
            Failure(
              message:
                  'No se pudo encontrar una dirección para esta ubicación.',
            ),
          );
        }
      } else {
        return Left(
          Failure(message: 'Error de servidor al contactar a Google Maps.'),
        );
      }
    } on DioException catch (e) {
      return Left(
        Failure(message: 'Error de red: Revise su conexión a internet.'),
      );
    } catch (e) {
      return Left(
        Failure(
          message: 'Ocurrió un error inesperado al procesar la ubicación.',
        ),
      );
    }
  }
}
