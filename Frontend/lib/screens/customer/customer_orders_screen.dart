import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';
import 'order_detail_screen.dart';

/// The customer Orders tab: active (in-progress) orders with tracking, and a
/// history list of completed/cancelled orders. Two tabs, no map.
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final _service = OrderService();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.myOrders();
  }

  Future<void> _reload() async {
    // Block body so the closure returns void — a fat-arrow here would return
    // the Future, which setState rejects.
    setState(() {
      _future = _service.myOrders();
    });
    await _future;
  }

  Future<void> _openOrder(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: id)),
    );
    // Refresh on return in case the status changed (e.g. weight approved).
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.ordersTitle),
          bottom: TabBar(
            tabs: [Tab(text: l10n.navActive), Tab(text: l10n.navHistory)],
          ),
        ),
        body: FutureBuilder<List<Order>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
                onRetry: _reload,
              );
            }
            final orders = snapshot.data!;
            final active = orders.where((o) => o.status.isActive).toList();
            final history = orders.where((o) => o.status.isTerminal).toList();

            return TabBarView(
              children: [
                _OrderList(
                  orders: active,
                  emptyText: l10n.ordersEmptyActive,
                  onTap: _openOrder,
                  onRefresh: _reload,
                ),
                _OrderList(
                  orders: history,
                  emptyText: l10n.ordersEmptyHistory,
                  onTap: _openOrder,
                  onRefresh: _reload,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final String emptyText;
  final void Function(int id) onTap;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.emptyText,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(emptyText, style: AppTypography.body)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          return _OrderCard(order: order, onTap: () => onTap(order.id));
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = order.finalTotal;
    final itemCount = order.items.length;
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.laundromat?.name ?? l10n.ordersLaundromatFallback,
                      style: AppTypography.heading2,
                    ),
                  ),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.orderNumber(order.id)} · ${l10n.ordersItemCount(itemCount)}'
                '${order.isKilo ? ' · ${l10n.ordersPerKgSuffix}' : ''}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (order.needsWeightApproval)
                    Text(l10n.ordersActionConfirmPrice,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.primaryDark))
                  else
                    Text(order.status.localizedLabel(l10n),
                        style: AppTypography.caption),
                  Text(
                    total != null
                        ? l10n.moneyRp(total.toStringAsFixed(0))
                        : (order.isKilo ? l10n.ordersWeighedAtPickup : '—'),
                    style: AppTypography.price,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppTypography.body),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
                onPressed: () => onRetry(),
                child: Text(AppLocalizations.of(context).commonRetry)),
          ],
        ),
      ),
    );
  }
}
