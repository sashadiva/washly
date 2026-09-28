import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../theme/app_theme.dart';
import '../account/account_settings_screen.dart';
import '../discovery_screen.dart';

/// Customer bottom-nav shell. Home/Orders are placeholders in Phase 0 and are
/// built out in later phases; Discovery is the existing screen; Profile hosts
/// account settings.
class CustomerHomeShell extends StatefulWidget {
  const CustomerHomeShell({super.key});

  @override
  State<CustomerHomeShell> createState() => _CustomerHomeShellState();
}

class _CustomerHomeShellState extends State<CustomerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CustomerHomePlaceholder(),
      const DiscoveryScreen(),
      const _ComingSoon(title: 'Orders'),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Discovery'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CustomerHomePlaceholder extends StatelessWidget {
  const _CustomerHomePlaceholder();
  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Washly')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_laundry_service,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('Hi, $name', style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Your home hub arrives in a later phase. Use Discovery to browse laundromats.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title coming soon', style: AppTypography.body),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const AccountSettingsScreen();
}
