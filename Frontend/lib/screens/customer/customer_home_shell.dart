import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_bottom_nav.dart';
import '../account/account_settings_screen.dart';
import 'customer_home_screen.dart';
import 'customer_orders_screen.dart';
import 'vouchers_screen.dart';

/// Customer bottom-nav shell: Home | Vouchers | Orders | Profile.
class CustomerHomeShell extends StatefulWidget {
  const CustomerHomeShell({super.key});

  @override
  State<CustomerHomeShell> createState() => _CustomerHomeShellState();
}

class _CustomerHomeShellState extends State<CustomerHomeShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      AppNavItem(Icons.home_rounded, Icons.home_outlined, l10n.navHome),
      AppNavItem(Icons.confirmation_number_rounded,
          Icons.confirmation_number_outlined, l10n.navVouchers),
      AppNavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined,
          l10n.navOrders),
      AppNavItem(Icons.person_rounded, Icons.person_outline, l10n.navProfile),
    ];

    final pages = [
      CustomerHomeScreen(
        onOpenDiscovery: () => _goTo(1),
        onOpenOrders: () => _goTo(2),
      ),
      const VouchersScreen(),
      const CustomerOrdersScreen(),
      const AccountSettingsScreen(),
    ];

    return Scaffold(
      // Overlay the floating nav on top of the body (no bottomNavigationBar
      // slot) so there's no grey Material bar behind it.
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
              onTap: _goTo,
            ),
          ),
        ],
      ),
    );
  }
}
