import 'package:flutter/material.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';
import '../account/account_settings_screen.dart';
import 'partner_claims_screen.dart';

/// Partner Profile tab: edit the shop (name, description, area, specialties,
/// open/closed) and reach account settings (name/phone/password/logout).
class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  final _service = PartnerService();
  late Future<PartnerProfile> _future;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _specialties = TextEditingController();
  bool _isOpen = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PartnerProfile> _load() async {
    final p = await _service.profile();
    _name.text = p.name;
    _desc.text = p.description ?? '';
    _area.text = p.areaLabel ?? '';
    _address.text = p.address;
    _specialties.text = p.specialties.join(', ');
    _isOpen = p.isOpen;
    _loaded = true;
    return p;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateProfile(
        name: _name.text.trim(),
        description: _desc.text.trim(),
        address: _address.text.trim(),
        areaLabel: _area.text.trim(),
        isOpen: _isOpen,
        specialties: _specialties.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop profile updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<PartnerProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (!_loaded &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                  style: AppTypography.body),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('Shop profile', style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Shop name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _area,
                decoration: const InputDecoration(
                  labelText: 'Area label (shown to customers)',
                  hintText: 'e.g. Kemang, South Jakarta',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Exact address (private, not shown to customers)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _specialties,
                decoration: const InputDecoration(
                  labelText: 'Specialties (comma separated)',
                  hintText: 'shoes, bags, express',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open for orders', style: AppTypography.body),
                value: _isOpen,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isOpen = v),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save shop profile'),
                ),
              ),
              const Divider(height: AppSpacing.xxl * 2, color: AppColors.border),
              Text('Warranty', style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PartnerClaimsScreen()),
                  );
                },
                icon: const Icon(Icons.gpp_maybe_outlined),
                label: const Text('Review warranty claims'),
              ),
              const Divider(height: AppSpacing.xxl * 2, color: AppColors.border),
              Text('Account', style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen()),
                  );
                },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Account settings & logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
