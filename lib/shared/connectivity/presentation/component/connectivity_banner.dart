import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/connectivity_cubit.dart';

// Envuelve el `child` que arma go_router (una pantalla completa, con su
// propio Scaffold) para mostrar encima un banner de "sin conexión" que
// sobrevive a cualquier navegación. Se engancha en el `builder` de
// MaterialApp.router en main.dart, un nivel por ARRIBA del propio Navigator
// -- mismo espíritu que ScaffoldWithNavBar engancha el bottom nav bar un
// nivel por encima del StatefulShellRoute (ver shared/presentation/
// component/scaffold_nav_bar.dart), pero a nivel de toda la app en vez de
// un solo shell, porque el banner debe verse sin importar la pantalla
// (incluidas splash/login, que quedan fuera del shell).
class ConnectivityBannerOverlay extends StatelessWidget {
  const ConnectivityBannerOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      buildWhen:
          (previous, current) => previous.isOffline != current.isOffline,
      builder: (context, state) {
        final isOffline = state.isOffline;

        return Column(
          children: [
            _ConnectivityBanner(visible: isOffline),
            Expanded(
              // El banner ya reserva su propio SafeArea arriba (ver más
              // abajo). Si no se le quita el padding superior a `child`
              // mientras está visible, el Scaffold/AppBar de la pantalla de
              // abajo vuelve a reservar la misma franja del status bar y
              // queda una franja en blanco duplicada debajo del banner.
              child:
                  isOffline
                      ? MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: child,
                      )
                      : child,
            ),
          ],
        );
      },
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.visible});

  final bool visible;

  static const _message = 'Sin conexión a internet';

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 280),
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeOut,
      sizeCurve: Curves.easeInOut,
      crossFadeState:
          visible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: Material(
        color: appColors.warning,
        elevation: 2,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Semantics(
              liveRegion: true,
              label: _message,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
