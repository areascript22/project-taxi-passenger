final class PlaceEntity {
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? formattedAddress;

  const PlaceEntity({
    required this.address,
    this.latitude,
    this.longitude,
    this.placeId,
    this.formattedAddress,
  });

  // Factory para crear desde autocomplete
  factory PlaceEntity.fromAutocomplete(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'];
    final text = placePrediction['text']['text'];
    final placeId = placePrediction['placeId'] as String?;

    return PlaceEntity(address: text, placeId: placeId, formattedAddress: text);
  }

  // Factory para crear desde place details
  factory PlaceEntity.fromDetails(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final address = json['formattedAddress'] as String? ?? '';

    double? lat;
    double? lng;

    if (location != null) {
      lat = (location['latitude'] as num?)?.toDouble();
      lng = (location['longitude'] as num?)?.toDouble();
    }

    return PlaceEntity(
      address: address,
      latitude: lat,
      longitude: lng,
      placeId: json['id'] as String?,
      formattedAddress: address,
    );
  }
}
