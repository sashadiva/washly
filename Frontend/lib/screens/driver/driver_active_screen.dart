import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/app_localizations.dart';
import '../../models/driver.dart';
import '../../models/order.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_status_bar.dart';
import '../../widgets/tracking_map.dart';

/// Driver Active tab (Gojek-style): a full-screen map with the laundromat +
/// driver pins and route line, and a draggable bottom sheet (peek -> full
/// screen) holding the current delivery's status and action.
class DriverActiveScreen extends StatefulWidget {
  const DriverActiveScreen({super.key});

  @override
  State<DriverActiveScreen> createState() => _DriverActiveScreenState();
}

class _DriverActiveScreenState extends State<DriverActiveScreen> {
  final _service = DriverService();

  DriverProfile? _profile;
  Order? _active;
  bool _loading = true;
  bool _busy = false;

  static const _fallback = LatLng(-6.2600, 106.8130);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _service.profile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
    try {
      final o = await _service.active();
      // Always reflect the result — including null, which means the delivery
      // was completed and we should switch to the "no active delivery" view.
      if (mounted) setState(() => _active = o);
    } catch (_) {
      // Only a genuine fetch failure lands here; keep the last known state.
    }
    if (mounted) setState(() => _loading = false);
  }

  LatLng get _mapCenter {
    final lm = _active?.laundromat;
    if (lm?.latitude != null && lm?.longitude != null) {
      return LatLng(lm!.latitude!, lm.longitude!);
    }
    if (_profile?.latitude != null && _profile?.longitude != null) {
      return LatLng(_profile!.latitude!, _profile!.longitude!);
    }
    return _fallback;
  }

  LatLng? get _driverPoint =>
      (_profile?.latitude != null && _profile?.longitude != null)
          ? LatLng(_profile!.latitude!, _profile!.longitude!)
          : null;

  void _error(Object e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.driverActiveErrorTitle),
        content: Text('$e'.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.driverActiveErrorOk)),
        ],
      ),
    );
  }

  Future<void> _run(Future<Order> Function() action,
      {String? successMessage}) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
      // Defensive: if the order is now terminal, make sure the active view
      // clears even if the follow-up fetch hiccupped.
      if (updated.status == OrderStatus.completed) {
        setState(() => _active = null);
      }
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading && _active == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_active == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.driverActiveTitle)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: [
              const SizedBox(height: 140),
              Center(
                child: Text(l10n.driverActiveNoActiveDelivery,
                    style: AppTypography.body),
              ),
            ],
          ),
        ),
      );
    }

    final order = _active!;
    return Scaffold(
      body: Column(
        children: [
          // Map fills the top portion of the screen.
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TrackingMap(
                    laundromat: _mapCenter,
                    driver: _driverPoint,
                    fill: true,
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: FloatingActionButton.small(
                        heroTag: 'driver-active-refresh',
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        onPressed: _load,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Static delivery panel pinned to the bottom.
          _deliveryPanel(l10n, order),
        ],
      ),
    );
  }

  Widget _deliveryPanel(AppLocalizations l10n, Order order) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Extra bottom padding clears the floating bottom nav (72 tall + its
          // 12 bottom margin) so the action button is never hidden behind it.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md + 84,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.driverActiveCurrentDelivery(order.id),
                  style: AppTypography.heading2),
              const SizedBox(height: AppSpacing.lg),
              DriverStatusBar(status: order.status),
              const SizedBox(height: AppSpacing.lg),
              ..._legAddresses(l10n, order),
              const SizedBox(height: AppSpacing.lg),
              _action(l10n, order),
            ],
          ),
        ),
      ),
    );
  }

  // Leg-aware addresses: on the pickup leg the driver goes to the customer and
  // then the laundromat; on the delivery leg, laundromat -> customer.
  List<Widget> _legAddresses(AppLocalizations l10n, Order order) {
    final shop = order.laundromat?.name ?? l10n.driverActiveLaundromatFallback;
    final isPickupLeg = order.status == OrderStatus.driverAssigned ||
        order.status == OrderStatus.pickedUp;
    if (isPickupLeg) {
      return [
        _addressRow(Icons.person_pin_circle_outlined,
            l10n.driverActiveCollectFrom(order.pickupAddress)),
        const SizedBox(height: AppSpacing.sm),
        _addressRow(Icons.storefront_outlined, l10n.driverActiveDropAt(shop)),
      ];
    }
    return [
      _addressRow(
          Icons.storefront_outlined, l10n.driverActiveCollectFrom(shop)),
      const SizedBox(height: AppSpacing.sm),
      _addressRow(Icons.location_on_outlined,
          l10n.driverActiveDeliverTo(order.deliveryAddress)),
    ];
  }

  Widget _addressRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.body)),
      ],
    );
  }

  Widget _action(AppLocalizations l10n, Order order) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (order.status) {
      case OrderStatus.driverAssigned:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(() => _service.markPickedUp(order.id),
                successMessage: l10n.driverActivePickedUpSuccess),
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(l10n.driverActiveMarkPickedUp),
          ),
        );
      case OrderStatus.pickedUp:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(
                () => _service.markArrivedAtLaundromat(order.id),
                successMessage: l10n.driverActiveArrivedSuccess),
            icon: const Icon(Icons.storefront_outlined),
            label: Text(l10n.driverActiveMarkArrived),
          ),
        );
      case OrderStatus.outForDelivery:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(() => _service.markDelivered(order.id),
                successMessage: l10n.driverActiveDeliveredSuccess),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.driverActiveMarkDelivered),
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
                  l10n.driverActiveWaitingOn(
                      order.status.localizedLabel(l10n)),
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        );
    }
  }
}
