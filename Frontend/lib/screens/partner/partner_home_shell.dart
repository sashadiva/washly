import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../theme/app_theme.dart';
import '../account/account_settings_screen.dart';

/// Partner bottom-nav shell. Dashboard/Orders/Services are placeholders in
/// Phase 0; Profile hosts account settings (shop editor is added in Phase 3).
class PartnerHomeShell extends StatefulWidget {
  const PartnerHomeShell({super.key});

  @override
  State<PartnerHomeShell> createState() => _PartnerHomeShellState();
}

class _PartnerHomeShellState extends State<PartnerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    final pages = [
      _Placeholder(title: 'Dashboard', greeting: 'Hi, $name'),
      const _Placeholder(title: 'Orders'),
      const _Placeholder(title: 'Services'),
      const AccountSettingsScreen(),
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
