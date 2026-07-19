import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:passenger_app/features/booking/domain/repository/booking_repository.dart';
import '../../../../core/error/errors.dart';
import '../../domain/entity/request_entity.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseDatabase database;

  BookingRepositoryImpl({required this.database});

  @override
  Future<Either<Failure, String>> requestTaxi({
    required RequestEntity request,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return Left(
          Failure(message: 'Usuario no autenticado. Inicie sesión nuevamente.'),
        );
      }

      final String userId = currentUser.uid;

      // 1. Reference directly to /taxi_requests/{userId}
      final DatabaseReference requestRef = database.ref()
          .child('taxi_requests')
          .child(userId); // 👈 This is the key: userId

      // 2. Generate a unique rideId (for tracking purposes)
      final String rideId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Structure the data payload
      final Map<String, dynamic> rideData = {
        'rideId': rideId,
        'userId': userId, // Keep this for queries
        'passenger': {
          'name': request.userName,
          'profileImage': request.userProfileImage,
        },
        'pickupLocation': {
          'latitude': request.pickupLat,
          'longitude': request.pickupLng,
          'address': request.pickupAddress,
        },
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp, // For tracking updates
      };

      // 4. Write the data - this will CREATE or UPDATE
      await requestRef.set(rideData); // 👈 No .push() here!

      // 5. Return the rideId
      return Right(rideId);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo solicitar el taxi. Intente de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelTaxiRequest() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return Left(
          Failure(message: 'Usuario no autenticado. Inicie sesión nuevamente.'),
        );
      }

      final String userId = currentUser.uid;

      final DatabaseReference requestRef = database.ref()
          .child('taxi_requests')
          .child(userId);

      await requestRef.remove();

      return Right(unit);
    } catch (e) {
      return Left(
        Failure(message: 'No se pudo cancelar la solicitud. Intente de nuevo.'),
      );
    }
  }

}
