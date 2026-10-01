import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_bottom_nav.dart';
import 'driver_home_screen.dart';
import 'driver_active_screen.dart';
import 'driver_history_screen.dart';
import 'driver_profile_screen.dart';

/// Driver bottom-nav shell: Home | Active | History | Profile. Home holds the
/// availability/vehicle section and delivery offers; Active is the full-screen
/// map + static delivery panel for the current delivery.
class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = const [
      DriverHomeScreen(),
      DriverActiveScreen(),
      DriverHistoryScreen(),
      DriverProfileScreen(),
    ];

    return Scaffold(
      // Overlay the floating nav on top of the body so there's no grey bar
      // behind it.
      body: Stack(
        children: [
          Positioned.fill(child: pages[_index]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              index: _index,
              onTap: (i) => setState(() => _index = i),
              items: [
                AppNavItem(
                    Icons.home_rounded, Icons.home_outlined, l10n.driverNavHome),
                AppNavItem(Icons.two_wheeler, Icons.two_wheeler_outlined,
                    l10n.driverNavActive),
                AppNavItem(Icons.history_rounded, Icons.history,
                    l10n.driverNavHistory),
                AppNavItem(Icons.person_rounded, Icons.person_outline,
                    l10n.driverNavProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
