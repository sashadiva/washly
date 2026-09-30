import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.confirmation_number_rounded, Icons.confirmation_number_outlined,
        'Vouchers'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders'),
    (Icons.person_rounded, Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: pages[_index],
      bottomNavigationBar: _ModernNavBar(
        index: _index,
        items: _items,
        onTap: _goTo,
      ),
    );
  }
}

/// A rounded, floating bottom navigation bar. The selected item shows a filled
/// icon inside a soft pill; others are muted outlines.
class _ModernNavBar extends StatelessWidget {
  final int index;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;

  const _ModernNavBar({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          // Max rounding: half the height, so the ends form a half circle.
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == index;
            final (activeIcon, inactiveIcon, label) = items[i];
            return _NavItem(
              icon: selected ? activeIcon : inactiveIcon,
              label: label,
              selected: selected,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 3),
          // Label always visible below the icon.
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
