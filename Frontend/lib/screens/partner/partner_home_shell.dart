import 'package:flutter/material.dart';
import 'partner_dashboard_screen.dart';
import 'partner_orders_screen.dart';
import 'partner_services_screen.dart';
import 'partner_profile_screen.dart';

/// Partner bottom-nav shell: Dashboard | Orders | Services | Profile.
class PartnerHomeShell extends StatefulWidget {
  const PartnerHomeShell({super.key});

  @override
  State<PartnerHomeShell> createState() => _PartnerHomeShellState();
}

class _PartnerHomeShellState extends State<PartnerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      PartnerDashboardScreen(),
      PartnerOrdersScreen(),
      PartnerServicesScreen(),
      PartnerProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.cleaning_services_outlined), label: 'Services'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
