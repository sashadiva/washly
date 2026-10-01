import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';

/// Edit the partner's shop profile (name, description, area, address,
/// specialties). The open/closed toggle lives on the Orders page.
class PartnerShopEditScreen extends StatefulWidget {
  const PartnerShopEditScreen({super.key});

  @override
  State<PartnerShopEditScreen> createState() => _PartnerShopEditScreenState();
}

class _PartnerShopEditScreenState extends State<PartnerShopEditScreen> {
  final _service = PartnerService();
  late Future<PartnerProfile> _future;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _specialties = TextEditingController();
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
    _loaded = true;
    return p;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await _service.updateProfile(
        name: _name.text.trim(),
        description: _desc.text.trim(),
        address: _address.text.trim(),
        areaLabel: _area.text.trim(),
        specialties: _specialties.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.partnerShopEditUpdated),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
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
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _area.dispose();
    _address.dispose();
    _specialties.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.partnerShopEditTitle)),
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
              TextField(
                controller: _name,
                decoration:
                    InputDecoration(labelText: l10n.partnerShopEditNameLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _desc,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: l10n.partnerShopEditDescriptionLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _area,
                decoration: InputDecoration(
                  labelText: l10n.partnerShopEditAreaLabel,
                  hintText: l10n.partnerShopEditAreaHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _address,
                decoration: InputDecoration(
                  labelText: l10n.partnerShopEditAddressLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _specialties,
                decoration: InputDecoration(
                  labelText: l10n.partnerShopEditSpecialtiesLabel,
                  hintText: l10n.partnerShopEditSpecialtiesHint,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                      : Text(l10n.partnerShopEditSave),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
