import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_customer_screen.dart';
import 'register_partner_screen.dart';
import 'register_driver_screen.dart';

/// First screen for signed-out users: pick a role to register, or jump to login.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Icon(Icons.local_laundry_service,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.roleSelectTitle,
                  textAlign: TextAlign.center, style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.roleSelectSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _RoleCard(
                icon: Icons.person_outline,
                title: l10n.roleSelectCustomerTitle,
                subtitle: l10n.roleSelectCustomerSubtitle,
                onTap: () => _go(context, const RegisterCustomerScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.storefront_outlined,
                title: l10n.roleSelectPartnerTitle,
                subtitle: l10n.roleSelectPartnerSubtitle,
                onTap: () => _go(context, const RegisterPartnerScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.two_wheeler_outlined,
                title: l10n.roleSelectDriverTitle,
                subtitle: l10n.roleSelectDriverSubtitle,
                onTap: () => _go(context, const RegisterDriverScreen()),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.roleSelectHaveAccountQuestion,
                      style: AppTypography.body),
                  TextButton(
                    onPressed: () => _go(context, const LoginScreen()),
                    child: Text(l10n.roleSelectLoginAction,
                        style: AppTypography.subheading
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTypography.body),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
