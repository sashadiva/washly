import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/session.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver sign up'),
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
                AuthField(controller: _name, label: 'Full name'),
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
                    controller: _vehicleType,
                    label: 'Vehicle type (e.g. motorcycle)'),
                const SizedBox(height: AppSpacing.lg),
                AuthField(controller: _plateNumber, label: 'Plate number'),
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
