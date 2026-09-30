import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';

/// Driver Active tab: the current assignment with contextual actions
/// (mark picked up, mark delivered). Empty when nothing is assigned.
class DriverActiveScreen extends StatefulWidget {
  const DriverActiveScreen({super.key});

  @override
  State<DriverActiveScreen> createState() => _DriverActiveScreenState();
}

class _DriverActiveScreenState extends State<DriverActiveScreen> {
  final _service = DriverService();
  late Future<Order?> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _service.active();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.active());
    await _future;
  }

  Future<void> _run(Future<Order> Function() action) async {
    setState(() => _busy = true);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Delivery')),
      body: FutureBuilder<Order?>(
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
          final order = snapshot.data;
          if (order == null) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                      child: Text('No active delivery.',
                          style: AppTypography.body)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.laundromat?.name ?? 'Laundromat',
                          style: AppTypography.heading2),
                    ),
                    StatusChip(status: order.status),
                  ],
                ),
                Text('Order #${order.id}', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.lg),
                _addressCard('Pickup / Return', order.pickupAddress),
                const SizedBox(height: AppSpacing.md),
                _addressCard('Deliver to', order.deliveryAddress),
                const SizedBox(height: AppSpacing.xl),
                Text('Progress', style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.md),
                StatusTimeline(order: order),
                const SizedBox(height: AppSpacing.xl),
                _action(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _action(Order order) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (order.status) {
      case OrderStatus.driverAssigned:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(() => _service.markPickedUp(order.id)),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Mark picked up'),
          ),
        );
      case OrderStatus.outForDelivery:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(() => _service.markDelivered(order.id)),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark delivered'),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Waiting on the laundromat / customer: ${order.status.label}.',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _addressCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}
