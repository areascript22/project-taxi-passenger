import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/passenger_entity.dart';

class PassengerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? photoUrl;
  final String fcmToken;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PassengerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    required this.fcmToken,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PassengerModel.fromJson(Map<String, dynamic> json, {required String id}) {
    return PassengerModel(
      id: id,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      fcmToken: json['fcmToken'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PassengerModel.fromEntity(PassengerEntity entity) {
    return PassengerModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      photoUrl: entity.photoUrl,
      fcmToken: entity.fcmToken,
      status: entity.status,
    );
  }

  // No incluye id/createdAt/updatedAt: el id es el nombre del documento y
  // las marcas de tiempo las agrega el repositorio con FieldValue.serverTimestamp().
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'status': status,
    };
  }

  PassengerEntity toEntity() {
    return PassengerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
