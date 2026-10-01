import 'package:flutter/material.dart';
import '../account/account_settings_screen.dart';

/// Driver Profile tab. Vehicle info and the availability toggle now live on the
/// Home screen, so this tab is just the shared account settings (profile photo,
/// name/phone, password, language, logout) — same as the customer Profile tab.
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsScreen();
  }
}
