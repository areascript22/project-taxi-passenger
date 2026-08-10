import 'dart:io';
import 'package:flutter/material.dart';

class ProfileAvatarPicker extends StatelessWidget {
  final File? localImage;
  final String? networkImageUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const ProfileAvatarPicker({
    super.key,
    required this.localImage,
    required this.networkImageUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = localImage != null || networkImageUrl != null;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
              backgroundImage:
                  localImage != null
                      ? FileImage(localImage!)
                      : (networkImageUrl != null
                          ? NetworkImage(networkImageUrl!)
                          : null) as ImageProvider?,
              child:
                  isLoading
                      ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      )
                      : (!hasImage
                          ? Icon(
                            Icons.person,
                            size: 52,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          )
                          : null),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
