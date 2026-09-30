import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/partner_service.dart';
import '../../services/warranty_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';

/// Partner order management: incoming orders with contextual actions
/// (accept/reject, weigh-in entry for per-kg, mark ready).
class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  final _service = PartnerService();
  final _warranty = WarrantyService();
  late Future<List<Order>> _future;
  int? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _future = _service.orders();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.orders());
    await _future;
  }

  Future<void> _run(int orderId, Future<Order> Function() action) async {
    setState(() => _busyOrderId = orderId);
    try {
      await action();
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _promptWeigh(Order order) async {
    final ctrl = TextEditingController();
    final kg = await showDialog<double>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Enter measured weight', style: AppTypography.heading2),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              Navigator.pop(dctx, v);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (kg == null || kg <= 0) return;
    await _run(order.id, () => _service.weigh(order.id, kg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}'.replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                        onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text('No orders yet.', style: AppTypography.body)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: orders.length,
              itemBuilder: (context, i) => _orderCard(orders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    final busy = _busyOrderId == order.id;
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order #${order.id}',
                      style: AppTypography.heading2),
                ),
                StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${order.isKilo ? 'Per kg' : 'Per item'} · '
              '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...order.items.map((item) {
              final unit = item.isKilo ? 'kg' : 'pcs';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${item.quantity}$unit ${item.serviceName}',
                    style: AppTypography.body),
              );
            }),
            if (order.pickupAddress.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(order.pickupAddress,
                        style: AppTypography.caption),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (order.declaredItems.isNotEmpty) ...[
              _intakeBlock(order, busy),
              const SizedBox(height: AppSpacing.sm),
            ],
            _actions(order, busy),
          ],
        ),
      ),
    );
  }

  Widget _intakeBlock(Order order, bool busy) {
    final unconfirmed =
        order.declaredItems.where((d) => !d.confirmedReceived).toList();
    // Once past pickup the partner has the laundry and can confirm intake.
    final canIntake = order.status != OrderStatus.pendingAcceptance &&
        order.status != OrderStatus.accepted &&
        order.status != OrderStatus.driverAssigned &&
        order.status != OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Declared items', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          ...order.declaredItems.map((d) => Row(
                children: [
                  Icon(
                    d.confirmedReceived
                        ? Icons.verified
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: d.confirmedReceived
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(d.label, style: AppTypography.caption)),
                ],
              )),
          if (unconfirmed.isNotEmpty && canIntake) ...[
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: busy ? null : () => _confirmIntake(order),
              child: const Text('Confirm items received'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmIntake(Order order) async {
    setState(() => _busyOrderId = order.id);
    try {
      final items = order.declaredItems
          .map((d) => {'declaredItemId': d.id, 'confirmed': true})
          .toList();
      await _warranty.confirmIntake(order.id, items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Declared items confirmed.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Widget _actions(Order order, bool busy) {
    if (busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    switch (order.status) {
      case OrderStatus.pendingAcceptance:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _run(order.id, () => _service.reject(order.id)),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _run(order.id, () => _service.accept(order.id)),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case OrderStatus.pickedUp:
        // Per-kg orders are weighed after pickup.
        if (order.isKilo) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _promptWeigh(order),
              icon: const Icon(Icons.scale_outlined),
              label: const Text('Enter weight'),
            ),
          );
        }
        return _hint('Waiting for the wash to begin after payment.');
      case OrderStatus.washing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(order.id, () => _service.markReady(order.id)),
            icon: const Icon(Icons.check),
            label: const Text('Mark ready for delivery'),
          ),
        );
      case OrderStatus.weighedAwaitingConfirm:
        return _hint('Waiting for the customer to approve the weighed price.');
      case OrderStatus.awaitingPayment:
        return _hint('Waiting for the customer to pay.');
      default:
        return _hint(order.status.label);
    }
  }

  Widget _hint(String text) => Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: AppTypography.caption)),
        ],
      );
}
