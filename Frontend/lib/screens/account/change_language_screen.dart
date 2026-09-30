import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/locale_store.dart';
import '../../theme/app_theme.dart';

/// Dedicated Change Language page: English / Indonesian radio options (radio on
/// the right), applied with a Confirm button.
class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<LocaleStore>().locale.languageCode;
  }

  Future<void> _confirm() async {
    await context.read<LocaleStore>().setLocale(Locale(_selected));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Language updated.'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Language')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v!),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: LocaleStore.supported.map((entry) {
                    final (locale, label) = entry;
                    final code = locale.languageCode;
                    final selected = code == _selected;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => setState(() => _selected = code),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(label,
                                    style: AppTypography.subheading),
                              ),
                              Radio<String>(
                                value: code,
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    child: const Text('Confirm'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
