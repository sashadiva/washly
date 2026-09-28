import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../theme/app_theme.dart';
import '../account/account_settings_screen.dart';

/// Driver bottom-nav shell. Offers/Active/History are placeholders in Phase 0;
/// Profile hosts account settings (availability toggle is added in Phase 4).
class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    final pages = [
      _Placeholder(title: 'Offers', greeting: 'Hi, $name'),
      const _Placeholder(title: 'Active'),
      const _Placeholder(title: 'History'),
      const AccountSettingsScreen(),
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
          NavigationDestination(
              icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  final String? greeting;
  const _Placeholder({required this.title, this.greeting});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (greeting != null) ...[
              Text(greeting!, style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text('$title coming soon', style: AppTypography.body),
          ],
        ),
      ),
    );
  }
}
