import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionWidget extends StatelessWidget {
  final TextStyle? style;
  final String prefix;
  final bool showBuildNumber;
  final Widget? loadingPlaceholder;

  const AppVersionWidget({
    super.key,
    this.style,
    this.prefix = 'v',
    this.showBuildNumber = true,
    this.loadingPlaceholder,
  });

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
        final version = packageInfo.version;
        final buildNumber = packageInfo.buildNumber;

        final displayText =
            showBuildNumber
                ? '$prefix$version ($buildNumber)'
                : '$prefix$version';

        return Text(
          displayText,
          style: style ?? TextStyle(color: Colors.grey.shade600, fontSize: 12),
        );
      },
    );
  }
}
