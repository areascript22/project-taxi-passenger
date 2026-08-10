import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:passenger_app/core/routing/app_routes.dart';
import 'package:passenger_app/shared/presentation/bloc/session/session_bloc.dart';
import '../../../../shared/presentation/component/custom_button.dart';

class ConfirmationPopup extends StatelessWidget {
  final VoidCallback? onAccept;

  const ConfirmationPopup({super.key, this.onAccept});

  static Future<void> show({
    required BuildContext context,
    VoidCallback? onAccept,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: context.read<SessionBloc>(),
          child: ConfirmationPopup(onAccept: onAccept),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionUnauthenticated) {
          context.goNamed(sessionRoute.name);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Cerrar Sesión",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          "¿Estás seguro de que deseas cerrar sesión?",
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Just close the dialog
              Navigator.of(context).pop();
            },
            child: Text(
              "Cancelar",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SizedBox(
              width: 120,
              child: CustomButton(
                textButton: "Cerrar Sesión",
                onTap: () {
                  // Dispatch logout event
                  context.read<SessionBloc>().add(SessionLogoutRequested());
                },
                backgroundColor: colorScheme.error,
                fontSize: 14,
                verticalPadding: 12,
                borderRadius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
