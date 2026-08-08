import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passenger_app/shared/domain/entity/place_entity.dart';
import '../../../../core/error/errors.dart';
import '../../domain/repository/location_search_repository.dart';
import '../../../../core/network/dio_client.dart';

class LocationSearchRepositoryImpl implements LocationSearchRepository {
  final String apiKey = dotenv.env['PLACES_API_KEY'] ?? '';

  @override
  Future<Either<Failure, List<PlaceEntity>>> getAutocompletePlaces({
    required String query,
  }) async {
    if (query.isEmpty) {
      return right(<PlaceEntity>[]);
    }

    try {
      final response = await DioClient.instance.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            // Añadimos placeId al field mask
            'X-Goog-FieldMask':
                'suggestions.placePrediction.text,suggestions.placePrediction.placeId',
          },
        ),
        data: {
          "input": query,
          "locationRestriction": {
            "circle": {
              "center": {"latitude": -1.6702, "longitude": -78.6631},
              "radius": 15000.0,
            },
          },
          // Incluimos solo lugares que tengan coordenadas
          "includePureServiceAreaBusinesses": false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final predictions = data['suggestions'] as List<dynamic>? ?? [];

        final List<PlaceEntity> places =
            predictions.map((suggestion) {
              return PlaceEntity.fromAutocomplete(suggestion);
            }).toList();

        return right(places);
      } else {
        return left(Failure(message: "Failed to fetch place suggestions."));
      }
    } on DioException catch (e) {
      debugPrint(
        "Places API Dio Error: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return left(Failure(message: "Failed to fetch place suggestions."));
    } catch (e) {
      debugPrint("Exception in getAutocompletePlaces: $e");
      return left(Failure(message: "An unexpected error occurred."));
    }
  }

  @override
  Future<Either<Failure, PlaceEntity>> getPlaceDetails({
    required String placeId,
  }) async {
    if (placeId.isEmpty) {
      return left(Failure(message: "Place ID is required"));
    }

    try {
      final response = await DioClient.instance.get(
        'https://places.googleapis.com/v1/places/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'id,formattedAddress,location,addressComponents',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final place = PlaceEntity.fromDetails(data);

        // Verificamos que tenga coordenadas
        if (place.latitude == null || place.longitude == null) {
          return left(Failure(message: "Place has no coordinates available"));
        }

        return right(place);
      } else {
        return left(Failure(message: "Failed to fetch place details."));
      }
    } on DioException catch (e) {
      debugPrint(
        "Places API Details Dio Error: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return left(Failure(message: "Failed to fetch place details."));
    } catch (e) {
      debugPrint("Exception in getPlaceDetails: $e");
      return left(Failure(message: "An unexpected error occurred."));
    }
  }
}
