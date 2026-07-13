import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passenger_app/features/booking/domain/entity/place_entity.dart';
import '../../../../core/error/errors.dart';
import '../../domain/repository/location_search_repository.dart';
import '../../../../core/network/dio_client.dart';

class LocationSearchRepositoryImpl implements LocationSearchRepository {

  @override
  Future<Either<Failure, List<PlaceEntity>>> getAutocompletePlaces({
    required String query,
  }) async {
    if (query.isEmpty) {
      return right(<PlaceEntity>[]);
    }

    final String apiKey = dotenv.env['PLACES_API_KEY'] ?? '';

    try {
      final response = await DioClient.instance.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'suggestions.placePrediction.text',
          },
        ),
        data: {
          "input": query,
          "locationBias": {
            "circle": {
              "center": {
                "latitude": -0.180653,
                "longitude": -78.467834
              },
              "radius": 50000.0
            }
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final predictions = data['suggestions'] as List<dynamic>? ?? [];

        final List<PlaceEntity> places = predictions.map((suggestion) {
          final placePrediction = suggestion['placePrediction'];
          final text = placePrediction['text']['text'];
          return PlaceEntity(address: text);
        }).toList();

        return right(places);
      } else {
        return left(Failure(message: "Failed to fetch place suggestions."));
      }
    } on DioException catch (e) {
      debugPrint("Places API Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      return left(Failure(message: "Failed to fetch place suggestions."));
    } catch (e) {
      debugPrint("Exception in getAutocompletePlaces: $e");
      return left(Failure(message: "An unexpected error occurred."));
    }
  }
}