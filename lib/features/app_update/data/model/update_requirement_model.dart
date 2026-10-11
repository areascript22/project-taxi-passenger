import 'package:passenger_app/features/app_update/domain/entity/update_requirement_entity.dart';

class UpdateRequirementModel {
  UpdateRequirementModel({
    required this.updateRequired,
    required this.minimumVersion,
    required this.storeUrl,
  });

  final bool updateRequired;
  final String minimumVersion;
  final String storeUrl;

  /// Los nombres de los campos son el contrato con el servidor
  /// (GET /api/public/app-version).
  factory UpdateRequirementModel.fromJson(Map<String, dynamic> json) {
    return UpdateRequirementModel(
      updateRequired: json['updateRequired'] == true,
      minimumVersion: (json['minimumVersion'] ?? '').toString(),
      storeUrl: (json['storeUrl'] ?? '').toString(),
    );
  }

  UpdateRequirementEntity toEntity() {
    return UpdateRequirementEntity(
      updateRequired: updateRequired,
      minimumVersion: minimumVersion,
      storeUrl: storeUrl,
    );
  }
}
