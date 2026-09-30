import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';

/// Driver Offers tab: pending pickup/delivery offers with accept/reject.
class DriverOffersScreen extends StatefulWidget {
  const DriverOffersScreen({super.key});

  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  final _service = DriverService();
  late Future<List<DeliveryOffer>> _future;
  int? _busyOfferId;

  @override
  void initState() {
    super.initState();
    _future = _service.offers();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.offers());
    await _future;
  }

  Future<void> _accept(DeliveryOffer offer) async {
    setState(() => _busyOfferId = offer.id);
    try {
      await _service.acceptOffer(offer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted. See the Active tab.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _reload();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  Future<void> _reject(DeliveryOffer offer) async {
    setState(() => _busyOfferId = offer.id);
    try {
      await _service.rejectOffer(offer.id);
      if (!mounted) return;
      await _reload();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$e'.replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: FutureBuilder<List<DeliveryOffer>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _retry('${snapshot.error}'.replaceFirst('Exception: ', ''));
          }
          final offers = snapshot.data!;
          if (offers.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No offers right now.\nMake sure you are Active in your Profile.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: offers.length,
              itemBuilder: (context, i) => _offerCard(offers[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _retry(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg, textAlign: TextAlign.center, style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _offerCard(DeliveryOffer offer) {
    final busy = _busyOfferId == offer.id;
    final order = offer.order;
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    offer.isPickup ? 'PICKUP' : 'DELIVERY',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const Spacer(),
                Text('Order #${order.id}', style: AppTypography.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(order.laundromat?.name ?? 'Laundromat',
                style: AppTypography.heading2),
            if ((order.laundromat?.areaLabel ?? '').isNotEmpty)
              Text(order.laundromat!.areaLabel!, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    offer.isPickup
                        ? 'Deliver to: ${order.deliveryAddress}'
                        : 'Deliver to: ${order.deliveryAddress}',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(offer),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _accept(offer),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
