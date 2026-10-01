import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wallet.dart';
import '../../services/loyalty_service.dart';
import '../../theme/app_theme.dart';

/// Lets the customer pick a voucher to apply at checkout. Pops with the chosen
/// [Voucher], or with the string 'none' to clear the current selection. Returns
/// null if dismissed without choosing. Shows an empty state when the wallet has
/// no available vouchers.
class VoucherSelectScreen extends StatefulWidget {
  /// The id of the voucher currently applied (to mark it selected), if any.
  final int? selectedVoucherId;
  const VoucherSelectScreen({super.key, this.selectedVoucherId});

  @override
  State<VoucherSelectScreen> createState() => _VoucherSelectScreenState();
}

class _VoucherSelectScreenState extends State<VoucherSelectScreen> {
  final _loyalty = LoyaltyService();
  late Future<Wallet> _future;

  @override
  void initState() {
    super.initState();
    _future = _loyalty.wallet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.voucherSelectTitle)),
      body: FutureBuilder<Wallet>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  '${snapshot.error}'.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ),
            );
          }

          final vouchers = snapshot.data?.availableVouchers ?? const [];
          if (vouchers.isEmpty) return _emptyState(l10n);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(l10n.voucherSelectCountAvailable(vouchers.length),
                  style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              ...vouchers.map((v) => _voucherTile(l10n, v)),
              const SizedBox(height: AppSpacing.md),
              // Clear any applied voucher.
              if (widget.selectedVoucherId != null)
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, 'none'),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.voucherSelectRemoveApplied),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _voucherTile(AppLocalizations l10n, Voucher v) {
    final selected = v.id == widget.selectedVoucherId;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => Navigator.pop(context, v),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.confirmation_number_outlined,
              color: AppColors.primary),
        ),
        title: Text(l10n.moneyRpOff(v.amountOff.toStringAsFixed(0)),
            style: AppTypography.subheading),
        subtitle: Text(l10n.voucherSelectDiscountVoucher,
            style: AppTypography.caption),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.voucherSelectEmptyTitle,
                style: AppTypography.subheading, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.voucherSelectEmptyBody,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
