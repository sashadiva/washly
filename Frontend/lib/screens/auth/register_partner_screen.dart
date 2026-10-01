import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_customer_screen.dart' show AuthField, AuthValidators, AuthButtonSpinner;

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({super.key});

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _businessName = TextEditingController();
  final _businessAddress = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _authService = AuthService();

  String _pricingModel = 'PER_KG';
  final _selectedSpecialties = <String>{};
  bool _submitting = false;

  static const _specialtyOptions = [
    'shoes',
    'bags',
    'dolls',
    'costumes',
    'express',
    'ironing',
    'kiloan',
    'dry clean',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _businessName.dispose();
    _businessAddress.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).registerPartnerSelectSpecialty),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _authService.registerPartner(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        businessName: _businessName.text.trim(),
        businessAddress: _businessAddress.text.trim(),
        latitude: double.parse(_latitude.text.trim()),
        longitude: double.parse(_longitude.text.trim()),
        pricingModel: _pricingModel,
        specialties: _selectedSpecialties.toList(),
      );
      if (!mounted) return;
      await context.read<AuthStore>().setSession(result.token, result.user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeForRole(result.user.role)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _coordinate(String? v, String label, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.commonFieldRequired(label);
    if (double.tryParse(v.trim()) == null) {
      return l10n.registerPartnerCoordinateInvalid;
    }
    return null;
  }

  /// Localized display label for a specialty tag. The tag value itself is kept
  /// as-is (it is sent to the API).
  String _specialtyLabel(String tag, AppLocalizations l10n) {
    switch (tag) {
      case 'shoes':
        return l10n.registerPartnerSpecialtyShoes;
      case 'bags':
        return l10n.registerPartnerSpecialtyBags;
      case 'dolls':
        return l10n.registerPartnerSpecialtyDolls;
      case 'costumes':
        return l10n.registerPartnerSpecialtyCostumes;
      case 'express':
        return l10n.registerPartnerSpecialtyExpress;
      case 'ironing':
        return l10n.registerPartnerSpecialtyIroning;
      case 'kiloan':
        return l10n.registerPartnerSpecialtyKiloan;
      case 'dry clean':
        return l10n.registerPartnerSpecialtyDryClean;
      default:
        return tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerPartnerTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(l10n.registerPartnerSectionAccount),
                AuthField(
                  controller: _name,
                  label: l10n.registerPartnerOwnerNameLabel,
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.registerPartnerOwnerNameLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _email,
                  label: l10n.commonEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthValidators.email(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _phone,
                  label: l10n.commonPhoneLabel,
                  keyboardType: TextInputType.phone,
                  requiredMessage:
                      l10n.commonFieldRequired(l10n.commonPhoneLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _password,
                  label: l10n.commonPasswordLabel,
                  obscure: true,
                  validator: AuthValidators.password(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _confirmPassword,
                  label: l10n.commonConfirmPasswordLabel,
                  obscure: true,
                  validator: AuthValidators.confirmPassword(
                      l10n, () => _password.text),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel(l10n.registerPartnerSectionBusiness),
                AuthField(
                  controller: _businessName,
                  label: l10n.registerPartnerBusinessNameLabel,
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.registerPartnerBusinessNameLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _businessAddress,
                  label: l10n.registerPartnerBusinessAddressLabel,
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.registerPartnerBusinessAddressLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                            labelText: l10n.registerPartnerLatitudeLabel),
                        validator: (v) => _coordinate(
                            v, l10n.registerPartnerLatitudeLabel, l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                            labelText: l10n.registerPartnerLongitudeLabel),
                        validator: (v) => _coordinate(
                            v, l10n.registerPartnerLongitudeLabel, l10n),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _pricingModel,
                  decoration: InputDecoration(
                      labelText: l10n.registerPartnerPricingModelLabel),
                  items: [
                    DropdownMenuItem(
                        value: 'PER_KG',
                        child: Text(l10n.registerPartnerPricingPerKg)),
                    DropdownMenuItem(
                        value: 'PER_ITEM',
                        child: Text(l10n.registerPartnerPricingPerItem)),
                  ],
                  onChanged: (v) =>
                      setState(() => _pricingModel = v ?? 'PER_KG'),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel(l10n.registerPartnerSectionSpecialties),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _specialtyOptions.map((tag) {
                    final selected = _selectedSpecialties.contains(tag);
                    return FilterChip(
                      label: Text(_specialtyLabel(tag, l10n)),
                      selected: selected,
                      selectedColor: AppColors.primaryLight,
                      checkmarkColor: AppColors.primary,
                      onSelected: (v) => setState(() {
                        v
                            ? _selectedSpecialties.add(tag)
                            : _selectedSpecialties.remove(tag);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const AuthButtonSpinner()
                      : Text(l10n.commonCreateAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: AppTypography.heading2),
    );
  }
}
