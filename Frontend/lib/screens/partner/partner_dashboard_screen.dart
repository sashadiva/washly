import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';

/// Partner sales dashboard: revenue and order counts from own paid orders.
class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final _service = PartnerService();
  late Future<PartnerDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.dashboard();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.dashboard());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Hi, $name', style: AppTypography.heading1),
            const SizedBox(height: AppSpacing.xs),
            Text('Here is how your shop is doing.',
                style: AppTypography.body),
            const SizedBox(height: AppSpacing.xl),
            FutureBuilder<PartnerDashboard>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    '${snapshot.error}'.replaceFirst('Exception: ', ''),
                    style: AppTypography.body.copyWith(color: AppColors.error),
                  );
                }
                final d = snapshot.data!;
                return Column(
                  children: [
                    _metric('Revenue (paid orders)',
                        'Rp ${d.revenue.toStringAsFixed(0)}',
                        Icons.payments_outlined, AppColors.success),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _metric('Paid', '${d.paidOrderCount}',
                              Icons.check_circle_outline, AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _metric('Completed', '${d.completedOrderCount}',
                              Icons.local_laundry_service_outlined,
                              AppColors.primaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _metric('Total orders', '${d.totalOrderCount}',
                        Icons.receipt_long_outlined, AppColors.textSecondary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.heading1.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
