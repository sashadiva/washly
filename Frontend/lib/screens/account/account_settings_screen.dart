import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/locale_store.dart';
import '../../core/profile_photo_store.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/role_select_screen.dart';
import '../partner/partner_shop_edit_screen.dart';
import 'change_language_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Shared account settings used under every role's Profile tab. Shows a profile
/// header (avatar + name + email) and a menu that navigates to dedicated pages
/// for editing profile, changing password, and language, plus logout.
///
/// [showShopProfile] adds a partner-only "Shop profile" tile that opens the
/// shop editor.
class AccountSettingsScreen extends StatefulWidget {
  final bool showShopProfile;
  const AccountSettingsScreen({super.key, this.showShopProfile = false});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthStore>().currentUser;
    if (user != null) {
      // Scope the local profile photo to this user.
      context.read<ProfilePhotoStore>().loadFor(user.id);
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountLogoutTitle),
        content: Text(l10n.accountLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accountLogoutTitle,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Future<void> _logout() async {
    await context.read<AuthStore>().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (route) => false,
    );
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser;
    final photo = context.watch<ProfilePhotoStore>().dataUri;
    final localeCode = context.watch<LocaleStore>().locale.languageCode;
    final l10n = AppLocalizations.of(context);
    final languageLabel =
        localeCode == 'id' ? l10n.languageIndonesian : l10n.languageEnglish;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
          children: [
            _profileHeader(user?.name ?? '-', user?.email ?? '-', photo),
            const SizedBox(height: AppSpacing.xl),

            if (widget.showShopProfile) ...[
              _MenuTile(
                icon: Icons.storefront_outlined,
                title: l10n.accountShopProfile,
                onTap: () => _open(const PartnerShopEditScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            _MenuTile(
              icon: Icons.person_outline,
              title: l10n.accountEditProfile,
              onTap: () => _open(const EditProfileScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.lock_outline,
              title: l10n.accountChangePassword,
              onTap: () => _open(const ChangePasswordScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.language_outlined,
              title: l10n.accountChangeLanguage,
              trailingText: languageLabel,
              onTap: () => _open(const ChangeLanguageScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.logout,
              title: l10n.accountLogoutTitle,
              danger: true,
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(String name, String email, String? photo) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ProfileAvatar(name: name, dataUri: photo, size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2),
                const SizedBox(height: AppSpacing.xs),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable menu row that navigates to a page (chevron) or runs an action.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final String? trailingText;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    final accent = danger ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color:
              danger ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(title,
                    style: AppTypography.subheading.copyWith(color: color)),
              ),
              if (trailingText != null) ...[
                Text(trailingText!, style: AppTypography.caption),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (!danger)
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
