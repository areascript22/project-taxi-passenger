import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Make sure to import this

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.35);

    return Scaffold(
      // The body is the shell itself, which renders the current branch's UI[cite: 7]
      body: navigationShell,

      // Use ClipRRect to clip the navbar's rectangular shape into rounded corners
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24.0), // Adjust the radius size to your liking
        ),
        child: BottomNavigationBar(
          backgroundColor: colorScheme.surface,
          currentIndex: navigationShell.currentIndex,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,

          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/svg/location.svg',
                width: 24,
                height: 24,
                // Color filtering allows the icon to respect selected/unselected state colors
                colorFilter: ColorFilter.mode(unselectedColor, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/svg/location.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
              label: 'Pedir',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/svg/profile.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(unselectedColor, BlendMode.srcIn),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/svg/profile.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(selectedColor, BlendMode.srcIn),
              ),
              label: 'Perfil',
            ),
          ],
          onTap: _onTap,
        ),
      ),
    );
  }

  void _onTap(int index) {
    // El bottom bar solo navega ENTRE branches. Volver a tocar la pestaña ya
    // activa no debe hacer nada -- en particular, no debe resetear el branch
    // a su ruta inicial: si el pasajero está en RideTrackingScreen (dentro
    // del branch "Pedir") y vuelve a tocar "Pedir", debe quedarse ahí, no
    // volver a la pantalla de solicitar viaje.
    if (index == navigationShell.currentIndex) return;
    navigationShell.goBranch(index);
  }
}
