import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';

/// Driver History tab: a clean list of completed deliveries.
class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _service = DriverService();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.history();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.history();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.driverHistoryTitle)),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', ''),
                  style: AppTypography.body),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 44, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.driverHistoryEmpty,
                            style: AppTypography.body),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              itemCount: orders.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      l10n.driverHistoryCount(orders.length),
                      style: AppTypography.caption,
                    ),
                  );
                }
                return _HistoryCard(order: orders[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Order order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = order.finalTotal;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: laundromat + completed badge.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        order.laundromat?.name ??
                            l10n.driverHistoryLaundromatFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.subheading),
                    Text(l10n.driverHistoryOrderCompleted(order.id),
                        style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg * 1.5, color: AppColors.border),
          // Delivery address.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(order.deliveryAddress,
                    style: AppTypography.caption),
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.driverHistoryOrderTotal,
                    style: AppTypography.caption),
                const Spacer(),
                Text(l10n.driverHistoryMoneyRp(total.toStringAsFixed(0)),
                    style: AppTypography.price),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
