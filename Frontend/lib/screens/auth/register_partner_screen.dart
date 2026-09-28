import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/session.dart';
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
        const SnackBar(content: Text('Select at least one specialty.')),
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

  String? _coordinate(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner sign up'),
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
                const _SectionLabel('Account'),
                AuthField(controller: _name, label: 'Owner name'),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _phone,
                  label: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _password,
                  label: 'Password',
                  obscure: true,
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _confirmPassword,
                  label: 'Confirm password',
                  obscure: true,
                  validator:
                      AuthValidators.confirmPassword(() => _password.text),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel('Business'),
                AuthField(controller: _businessName, label: 'Business name'),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                    controller: _businessAddress, label: 'Business address'),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                        validator: (v) => _coordinate(v, 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        validator: (v) => _coordinate(v, 'Longitude'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _pricingModel,
                  decoration:
                      const InputDecoration(labelText: 'Pricing model'),
                  items: const [
                    DropdownMenuItem(
                        value: 'PER_KG', child: Text('Per kilogram')),
                    DropdownMenuItem(
                        value: 'PER_ITEM', child: Text('Per item')),
                  ],
                  onChanged: (v) =>
                      setState(() => _pricingModel = v ?? 'PER_KG'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel('Specialties'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _specialtyOptions.map((tag) {
                    final selected = _selectedSpecialties.contains(tag);
                    return FilterChip(
                      label: Text(tag),
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
                      : const Text('Create account'),
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
