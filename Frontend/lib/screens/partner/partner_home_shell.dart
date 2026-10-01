import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_bottom_nav.dart';
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
    final l10n = AppLocalizations.of(context);
    final items = [
      AppNavItem(
          Icons.dashboard_rounded, Icons.dashboard_outlined, l10n.navDashboard),
      AppNavItem(
          Icons.receipt_long_rounded, Icons.receipt_long_outlined, l10n.navOrders),
      AppNavItem(Icons.cleaning_services_rounded,
          Icons.cleaning_services_outlined, l10n.navServices),
      AppNavItem(Icons.person_rounded, Icons.person_outline, l10n.navProfile),
    ];
    final pages = const [
      PartnerDashboardScreen(),
      PartnerOrdersScreen(),
      PartnerServicesScreen(),
      PartnerProfileScreen(),
    ];

    return Scaffold(
      // Overlay the floating nav on top of the body so there's no grey bar.
      body: Stack(
        children: [
          Positioned.fill(child: pages[_index]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNav(
              index: _index,
              items: items,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}
