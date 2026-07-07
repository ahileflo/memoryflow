import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/brand_bottom_nav.dart';

/// Scaffold that hosts the three tab branches (Home / Gifts / Profile) and the
/// persistent [BrandBottomNav]. Tab state is preserved by the
/// StatefulShellRoute's IndexedStack.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab returns it to its initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BrandBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
