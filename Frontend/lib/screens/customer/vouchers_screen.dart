import 'package:flutter/material.dart';
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
    setState(() => _redeemingTierId = tier.id);
    try {
      await _loyalty.redeem(tier.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Redeemed a Rp ${tier.amountOff.toStringAsFixed(0)} voucher!'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Vouchers')),
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _balanceCard(balance),
                const SizedBox(height: AppSpacing.xxl),
                Text('Redeem Points', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.xs),
                Text('Pick a reward to redeem with your points.',
                    style: AppTypography.caption),
                const SizedBox(height: AppSpacing.md),
                if (tiers.isEmpty)
                  Text('No rewards available right now.',
                      style: AppTypography.body)
                else
                  ...tiers.map((t) => _tierCard(t, balance)),
                const SizedBox(height: AppSpacing.xxl),
                Text('Your Vouchers', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.md),
                if (vouchers.isEmpty)
                  Text('No vouchers yet. Redeem points to get one.',
                      style: AppTypography.body)
                else
                  ...vouchers.map(_voucherTile),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard(int balance) {
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
                  '$balance points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Earn 5 points per Rp 10.000 spent.',
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

  Widget _tierCard(RewardTier tier, int balance) {
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
                Text('Rp ${tier.amountOff.toStringAsFixed(0)} off',
                    style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.xs),
                Text('${tier.points} points',
                    style: AppTypography.caption),
                if (!canRedeem) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Need ${tier.points - balance} more points',
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
                  : const Text('Redeem'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voucherTile(Voucher v) {
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
                      'Rp ${v.amountOff.toStringAsFixed(0)} off',
                      style: AppTypography.subheading,
                    ),
                    Text(
                      v.used ? 'Used' : 'Available at checkout',
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
