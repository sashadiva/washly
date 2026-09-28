import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/customer/customer_home_shell.dart';
import '../screens/partner/partner_home_shell.dart';
import '../screens/driver/driver_home_shell.dart';
import 'auth_store.dart';

/// Returns the correct landing widget for the current session:
/// a valid token routes to the role home; otherwise to role selection.
Widget homeForSession(AuthStore auth) {
  if (!auth.isLoggedIn || auth.currentUser == null) {
    return const RoleSelectScreen();
  }
  return homeForRole(auth.currentUser!.role);
}

/// Maps a role to its home shell. Shells are placeholders in Phase 0 and are
/// fleshed out in later phases.
Widget homeForRole(UserRole role) {
  switch (role) {
    case UserRole.partner:
      return const PartnerHomeShell();
    case UserRole.driver:
      return const DriverHomeShell();
    case UserRole.customer:
      return const CustomerHomeShell();
  }
}
