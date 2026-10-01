import 'package:flutter/material.dart';
import '../account/account_settings_screen.dart';

/// Partner Profile tab. Shop-profile editing and the open/closed toggle have
/// moved (shop edit into the account area via the shared settings screen's
/// extra tile; open/closed to the Orders page), so this tab is the shared
/// account settings — same as the customer and driver Profile tabs.
class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountSettingsScreen(showShopProfile: true);
  }
}
