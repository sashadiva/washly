import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_customer_screen.dart' show AuthField, AuthValidators, AuthButtonSpinner;

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _vehicleType = TextEditingController();
  final _plateNumber = TextEditingController();
  final _authService = AuthService();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _vehicleType.dispose();
    _plateNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await _authService.registerDriver(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        vehicleType: _vehicleType.text.trim(),
        plateNumber: _plateNumber.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerDriverTitle),
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
                AuthField(
                  controller: _name,
                  label: l10n.commonFullNameLabel,
                  requiredMessage:
                      l10n.commonFieldRequired(l10n.commonFullNameLabel),
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
                  controller: _vehicleType,
                  label: l10n.registerDriverVehicleTypeLabel,
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.registerDriverVehicleTypeLabel),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthField(
                  controller: _plateNumber,
                  label: l10n.registerDriverPlateNumberLabel,
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.registerDriverPlateNumberLabel),
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
