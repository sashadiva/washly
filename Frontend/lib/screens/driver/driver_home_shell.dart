import 'package:flutter/material.dart';
import 'driver_offers_screen.dart';
import 'driver_active_screen.dart';
import 'driver_history_screen.dart';
import 'driver_profile_screen.dart';

/// Driver bottom-nav shell: Offers | Active | History | Profile.
class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DriverOffersScreen(),
      DriverActiveScreen(),
      DriverHistoryScreen(),
      DriverProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_offer_outlined), label: 'Offers'),
          NavigationDestination(
              icon: Icon(Icons.two_wheeler_outlined), label: 'Active'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
