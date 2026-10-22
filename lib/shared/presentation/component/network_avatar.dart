import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Avatar circular con una foto que viene de la red. A diferencia de
// NetworkImage (que solo cachea en memoria), CachedNetworkImage guarda el
// archivo en disco: la foto no se vuelve a descargar en cada arranque. La URL
// de Firebase Storage lleva un token que cambia al subir otra foto, así que la
// propia URL sirve de llave de caché.
//
// Sin URL, o si la descarga falla, muestra el icono de persona.
class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({super.key, required this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = photoUrl;

    final fallback = Icon(
      Icons.person_outline,
      color: colorScheme.primary,
      size: size * 0.58,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child:
          url == null || url.isEmpty
              ? fallback
              : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Decodifica a la resolución que se ve, no la foto completa.
                memCacheWidth:
                    (size * MediaQuery.devicePixelRatioOf(context)).round(),
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
    );
  }
}
