import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterCustomerScreen extends StatefulWidget {
  const RegisterCustomerScreen({super.key});

  @override
  State<RegisterCustomerScreen> createState() => _RegisterCustomerScreenState();
}

class _RegisterCustomerScreenState extends State<RegisterCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _authService = AuthService();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await _authService.registerCustomer(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
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
        title: Text(l10n.registerCustomerTitle),
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
                  requiredMessage: l10n.commonFieldRequired(
                      l10n.commonFullNameLabel),
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

// ---------------------------------------------------------------------------
// Shared auth form helpers (used by all registration screens).
// ---------------------------------------------------------------------------

class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  /// Message shown by the default "required" validator. When null, falls back
  /// to a plain "<label> is required" string (used only when no [validator] is
  /// supplied).
  final String? requiredMessage;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.requiredMessage,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        // Password fields get a show/hide toggle.
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility),
                tooltip: _obscured
                    ? l10n.commonShowPassword
                    : l10n.commonHidePassword,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
      validator: widget.validator ??
          (v) => (v == null || v.trim().isEmpty)
              ? (widget.requiredMessage ??
                  l10n.commonFieldRequired(widget.label))
              : null,
    );
  }
}

class AuthValidators {
  AuthValidators._();

  static String? Function(String?) email(AppLocalizations l10n) {
    return (v) {
      if (v == null || v.trim().isEmpty) return l10n.commonEmailRequired;
      final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!re.hasMatch(v.trim())) return l10n.commonEmailInvalid;
      return null;
    };
  }

  static String? Function(String?) password(AppLocalizations l10n) {
    return (v) {
      if (v == null || v.isEmpty) return l10n.commonPasswordRequired;
      if (v.length < 6) return l10n.commonPasswordTooShort;
      return null;
    };
  }

  /// Returns a validator that checks the confirm-password field matches the
  /// original password value.
  static String? Function(String?) confirmPassword(
      AppLocalizations l10n, String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return l10n.commonConfirmPasswordRequired;
      if (v != original()) return l10n.commonPasswordsDoNotMatch;
      return null;
    };
  }
}

class AuthButtonSpinner extends StatelessWidget {
  const AuthButtonSpinner({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child:
            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
