import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Make sure to import this

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is the shell itself, which renders the current branch's UI[cite: 7]
      body: navigationShell,

      // Use ClipRRect to clip the navbar's rectangular shape into rounded corners
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24.0), // Adjust the radius size to your liking
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.grey,
          // Set the gray background color
          currentIndex: navigationShell.currentIndex,
          //[cite: 7]
          // Optional: update colors for selected and unselected items so they contrast well with gray
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white70,

          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/svg/location.svg',
                width: 24,
                height: 24,
                // Color filtering allows the icon to respect selected/unselected state colors
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/svg/location.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Pedir',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/svg/profile.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/svg/profile.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Perfil',
            ),
          ],
          onTap: (int index) => _onTap(context, index), //[cite: 7]
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // goBranch switches the active navigation stack.[cite: 7]
    navigationShell.goBranch(
      index, //[cite: 7]
      // Optional but recommended: If you tap the active tab again,[cite: 7]
      // it pops the stack back to its root (e.g., PageY pops back to PageX).[cite: 7]
      initialLocation: index == navigationShell.currentIndex, //[cite: 7]
    );
  }
}
