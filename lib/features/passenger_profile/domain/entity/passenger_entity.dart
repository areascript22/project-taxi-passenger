class PassengerEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? photoUrl;
  final String fcmToken;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PassengerEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    this.fcmToken = '',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  PassengerEntity copyWith({String? photoUrl}) {
    return PassengerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
