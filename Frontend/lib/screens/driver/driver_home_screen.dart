import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/driver.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';

/// Driver Home tab: availability + vehicle section, and pending delivery
/// offers (accept/reject). The active delivery and its map live on the
/// separate Active tab.
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _service = DriverService();

  DriverProfile? _profile;
  List<DeliveryOffer> _offers = const [];
  bool _loading = true;
  bool _busy = false;
  bool _toggling = false;

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
      final list = await _service.offers();
      if (mounted) setState(() => _offers = list);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _error(Object e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.driverHomeErrorTitle),
        content: Text('$e'.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.driverHomeErrorOk)),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(DriverProfile p, bool active) async {
    setState(() => _toggling = true);
    try {
      await _service.setAvailability(active,
          latitude: p.latitude, longitude: p.longitude);
      if (!mounted) return;
      await _load();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _acceptOffer(DeliveryOffer offer) async {
    setState(() => _busy = true);
    try {
      await _service.acceptOffer(offer.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectOffer(DeliveryOffer offer) async {
    setState(() => _busy = true);
    try {
      await _service.rejectOffer(offer.id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: _loading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
                children: [
                  _brandHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  if (_profile != null) _availabilityVehicle(l10n, _profile!),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.driverHomeDeliveryOffers,
                      style: AppTypography.heading1),
                  const SizedBox(height: AppSpacing.sm),
                  if (_offers.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        _profile?.isActive == true
                            ? l10n.driverHomeNoOffers
                            : l10n.driverHomeTurnOnActive,
                        style: AppTypography.body,
                      ),
                    )
                  else
                    ..._offers.map((o) => _offerCard(l10n, o)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.local_laundry_service,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'Washly',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _availabilityVehicle(AppLocalizations l10n, DriverProfile p) {
    final active = p.isActive;
    final busy = p.isBusy;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: active ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busy
                      ? l10n.driverHomeStatusOnDelivery
                      : (active
                          ? l10n.driverHomeStatusActive
                          : l10n.driverHomeStatusNotActive),
                  style: AppTypography.subheading,
                ),
                Text(
                    l10n.driverHomeVehicleLine(p.vehicleType, p.plateNumber),
                    style: AppTypography.caption),
              ],
            ),
          ),
          if (_toggling)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: active,
              activeThumbColor: AppColors.primary,
              onChanged: busy ? null : (v) => _toggleAvailability(p, v),
            ),
        ],
      ),
    );
  }

  Widget _offerCard(AppLocalizations l10n, DeliveryOffer offer) {
    final order = offer.order;
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
                    offer.isPickup
                        ? l10n.driverHomeTagPickup
                        : l10n.driverHomeTagDelivery,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primaryDark)),
              ),
              const Spacer(),
              Text(l10n.driverHomeOrderNumber(order.id),
                  style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(order.laundromat?.name ?? l10n.driverHomeLaundromatFallback,
              style: AppTypography.subheading),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(l10n.driverHomeDeliverTo(order.deliveryAddress),
                    style: AppTypography.caption),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_busy)
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
                    onPressed: () => _rejectOffer(offer),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(l10n.driverHomeReject),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOffer(offer),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(l10n.driverHomeAccept),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
