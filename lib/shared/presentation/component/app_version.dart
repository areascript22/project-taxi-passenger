import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

// Lo que se le muestra al usuario es solo la versión "de marketing" (1.0.7):
// sin el sufijo de flavor/pre-release (-dev) ni el build number (+19). Es una
// decisión de presentación, así que vive acá: el valor real sigue intacto en
// pubspec/gradle y en lo que reporta el plugin.
String displayAppVersion({required String rawVersion}) {
  return rawVersion.split('+').first.split('-').first.trim();
}

class AppVersionWidget extends StatelessWidget {
  final TextStyle? style;
  final Widget? loadingPlaceholder;

  const AppVersionWidget({super.key, this.style, this.loadingPlaceholder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingPlaceholder ?? const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final packageInfo = snapshot.data!;
        final version = displayAppVersion(rawVersion: packageInfo.version);

        return Text(
          AppLocalizations.of(context).appVersionLabel(version),
          style:
              style ??
              TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
        );
      },
    );
  }
}
