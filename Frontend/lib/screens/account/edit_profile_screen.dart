import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/profile_photo_store.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';

/// Dedicated Edit Profile page: change photo (from gallery), name, and phone.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthStore>().currentUser;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    // Make sure the photo store is scoped to this user.
    if (user != null) {
      context.read<ProfilePhotoStore>().loadFor(user.id);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 75,
      );
      if (file == null) return; // user cancelled
      final bytes = await file.readAsBytes();
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      await context.read<ProfilePhotoStore>().setPhoto(dataUri);
      if (mounted) _toast(AppLocalizations.of(context).editProfilePhotoUpdated);
    } catch (e) {
      if (mounted) {
        _toast(
            AppLocalizations.of(context).editProfilePickerError(
                '$e'.replaceFirst('Exception: ', '')),
            error: true);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await _authService.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      await context.read<AuthStore>().updateUser(updated);
      if (!mounted) return;
      _toast(AppLocalizations.of(context).editProfileUpdated);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    final photo = context.watch<ProfilePhotoStore>().dataUri;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Photo + change action.
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileAvatar(name: name, dataUri: photo, size: 96),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _pickPhoto,
                    child: Text(l10n.editProfileChangePhoto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration:
                        InputDecoration(labelText: l10n.editProfileNameLabel),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.editProfileNameRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        InputDecoration(labelText: l10n.commonPhoneLabel),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.editProfilePhoneRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(l10n.editProfileSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
