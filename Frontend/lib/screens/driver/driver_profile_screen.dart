import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';
import '../account/account_settings_screen.dart';

/// Driver Profile tab: vehicle info, the Active / Not Active availability
/// toggle (labeled to avoid implying internet connectivity), and a link to
/// shared account settings (name/phone/password/logout).
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _service = DriverService();
  late Future<DriverProfile> _future;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _future = _service.profile();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.profile());
    await _future;
  }

  Future<void> _toggle(DriverProfile p, bool active) async {
    setState(() => _toggling = true);
    try {
      // Seed drivers are positioned near their partners; reuse the stored
      // location so nearest-driver matching keeps working.
      await _service.setAvailability(
        active,
        latitude: p.latitude,
        longitude: p.longitude,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DriverProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                  style: AppTypography.body),
            );
          }
          final p = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _availabilityCard(p),
              const SizedBox(height: AppSpacing.xl),
              Text('Vehicle', style: AppTypography.subheading),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full-height motorcycle icon panel to the left of the
                      // whole section (spans both vehicle-type and plate rows).
                      Container(
                        color: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: const Center(
                          child: Icon(Icons.two_wheeler,
                              color: AppColors.primary, size: 32),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.vehicleType, style: AppTypography.body),
                              Text(p.plateNumber, style: AppTypography.caption),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _availabilityCard(DriverProfile p) {
    final busy = p.isBusy;
    final active = p.isActive;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: active ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.bolt : Icons.bolt_outlined,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                busy
                    ? 'On a delivery'
                    : (active ? 'Active (receiving offers)' : 'Not Active'),
                style: AppTypography.subheading,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            busy
                ? 'Finish your current delivery to change this.'
                : 'Active means you can receive delivery offers. This is not about your internet connection.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_toggling)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(active ? 'Active' : 'Not Active',
                  style: AppTypography.body),
              value: active,
              activeThumbColor: AppColors.primary,
              onChanged: busy ? null : (v) => _toggle(p, v),
            ),
        ],
      ),
    );
  }
}
