import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wallet.dart';
import '../../services/loyalty_service.dart';
import '../../theme/app_theme.dart';

/// Loyalty vouchers hub: shows the point balance, a catalog of reward tiers the
/// customer can choose to redeem, and their redeemed vouchers (available/used).
class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final _loyalty = LoyaltyService();
  late Future<Wallet> _future;
  String? _redeemingTierId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _loyalty.wallet();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _redeem(RewardTier tier) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _redeemingTierId = tier.id);
    try {
      await _loyalty.redeem(tier.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n.vouchersRedeemedToast(tier.amountOff.toStringAsFixed(0))),
          backgroundColor: AppColors.success,
        ),
      );
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _redeemingTierId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vouchersTitle)),
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

          final wallet = snapshot.data;
          final balance = wallet?.balance ?? 0;
          final vouchers = wallet?.vouchers ?? const [];
          final tiers = wallet?.tiers ?? const [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              children: [
                _balanceCard(l10n, balance),
                const SizedBox(height: AppSpacing.xxl),
                Text(l10n.vouchersRedeemPoints, style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.vouchersRedeemSubtitle,
                    style: AppTypography.caption),
                const SizedBox(height: AppSpacing.md),
                if (tiers.isEmpty)
                  Text(l10n.vouchersNoRewards,
                      style: AppTypography.body)
                else
                  ...tiers.map((t) => _tierCard(l10n, t, balance)),
                const SizedBox(height: AppSpacing.xxl),
                Text(l10n.vouchersYourVouchers, style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.md),
                if (vouchers.isEmpty)
                  Text(l10n.vouchersEmpty,
                      style: AppTypography.body)
                else
                  ...vouchers.map((v) => _voucherTile(l10n, v)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard(AppLocalizations l10n, int balance) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homePoints(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.vouchersEarnRate,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(AppLocalizations l10n, RewardTier tier, int balance) {
    final canRedeem = balance >= tier.points;
    final busy = _redeemingTierId == tier.id;
    final anyBusy = _redeemingTierId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: canRedeem ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.moneyRpOff(tier.amountOff.toStringAsFixed(0)),
                    style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.vouchersTierPoints(tier.points),
                    style: AppTypography.caption),
                if (!canRedeem) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.vouchersNeedMorePoints(tier.points - balance),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed:
                  (!canRedeem || anyBusy) ? null : () => _redeem(tier),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                minimumSize: const Size(0, 40),
              ),
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l10n.commonRedeem),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voucherTile(AppLocalizations l10n, Voucher v) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            Container(
              color: v.used ? AppColors.surfaceMuted : AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Center(
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: v.used ? AppColors.textMuted : AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.moneyRpOff(v.amountOff.toStringAsFixed(0)),
                      style: AppTypography.subheading,
                    ),
                    Text(
                      v.used ? l10n.vouchersUsed : l10n.vouchersAvailableAtCheckout,
                      style: AppTypography.caption.copyWith(
                        color:
                            v.used ? AppColors.textMuted : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (v.used)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.check_circle_outline,
                    color: AppColors.textMuted, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
