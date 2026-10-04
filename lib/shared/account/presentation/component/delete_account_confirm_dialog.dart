import 'package:flutter/material.dart';
import 'package:passenger_app/l10n/app_localizations.dart';

class DeleteAccountConfirmDialog extends StatelessWidget {
  const DeleteAccountConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.deleteAccountTitle,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        l10n.deleteAccountDialogBody,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.commonCancel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.deleteAccountTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
