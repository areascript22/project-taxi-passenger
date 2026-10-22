import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passenger_app/core/error/errors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repository/geocoding_repository.dart';
import '../../utils/geocoding_result_parser.dart';

class GeocodingRepositoryImpl implements GeocodingRepository {
  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double lat,
    required double lng,
  }) async {
    final apiKey = dotenv.env['GEOCODING_API'];

    if (apiKey == null || apiKey.isEmpty) {
      return Left(Failure(code: FailureCode.mapsApiKeyMissing));
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
          final address = GeocodingResultParser.pickBestAddress(
            results: data['results'] as List<dynamic>,
            latitude: lat,
            longitude: lng,
          );

          if (address != null && address.isNotEmpty) {
            return Right(address);
          }

          return Left(
            Failure(code: FailureCode.addressNotFound),
          );
        } else {
          return Left(
            Failure(code: FailureCode.addressNotFound),
          );
        }
      } else {
        return Left(
          Failure(code: FailureCode.mapsServerError),
        );
      }
    } on DioException catch (e) {
      return Left(
        Failure(code: FailureCode.networkError),
      );
    } catch (e) {
      return Left(
        Failure(code: FailureCode.locationProcessFailed),
      );
    }
  }
}
