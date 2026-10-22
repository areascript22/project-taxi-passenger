import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:passenger_app/features/app_update/presentation/screen/force_update_screen.dart';

/// Envuelve TODA la app (se coloca en el `builder` del MaterialApp.router) y
/// la reemplaza por [ForceUpdateScreen] cuando el servidor exige actualizar.
///
/// Mientras se consulta, o si la consulta falla, deja pasar a [child]: nunca
/// se bloquea a nadie por no haber podido preguntar.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      buildWhen: (previous, current) => previous.isUpdateRequired != current.isUpdateRequired,
      builder: (context, state) {
        if (state.isUpdateRequired) {
          return const ForceUpdateScreen();
        }
        return child;
      },
    );
  }
}
