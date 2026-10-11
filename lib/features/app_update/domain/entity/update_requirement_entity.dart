/// Lo que responde el servidor sobre la versión de esta app: si todavía se
/// admite, cuál es la mínima y dónde se descarga.
class UpdateRequirementEntity {
  const UpdateRequirementEntity({
    required this.updateRequired,
    required this.minimumVersion,
    required this.storeUrl,
  });

  final bool updateRequired;
  final String minimumVersion;
  final String storeUrl;
}
