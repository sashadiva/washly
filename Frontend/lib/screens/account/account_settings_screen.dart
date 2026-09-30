import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/locale_store.dart';
import '../../core/profile_photo_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/role_select_screen.dart';
import 'change_language_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Shared account settings used under every role's Profile tab. Shows a profile
/// header (avatar + name + email) and a menu that navigates to dedicated pages
/// for editing profile, changing password, and language, plus logout.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.error)),
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
    final languageLabel = localeCode == 'id' ? 'Indonesian' : 'English';

    return Scaffold(
      appBar: AppBar(title: const Text('Account settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _profileHeader(user?.name ?? '-', user?.email ?? '-', photo),
            const SizedBox(height: AppSpacing.xl),

            _MenuTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => _open(const EditProfileScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => _open(const ChangePasswordScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.language_outlined,
              title: 'Change Language',
              trailingText: languageLabel,
              onTap: () => _open(const ChangeLanguageScreen()),
            ),
            const SizedBox(height: AppSpacing.md),

            _MenuTile(
              icon: Icons.logout,
              title: 'Log out',
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
