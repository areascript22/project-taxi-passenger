class RequestEntity {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final String userId;
  final String userName;
  final String userProfileImage;

  const RequestEntity({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
  });
}