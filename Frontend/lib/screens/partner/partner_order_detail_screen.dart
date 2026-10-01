import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../models/warranty.dart';
import '../../services/partner_service.dart';
import '../../services/warranty_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';

/// Full partner-side order detail: items, declared-item intake, status actions
/// (accept/reject, weigh, mark ready), the customer review when completed, and
/// inline warranty-claim review.
class PartnerOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const PartnerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<PartnerOrderDetailScreen> createState() =>
      _PartnerOrderDetailScreenState();
}

class _PartnerOrderDetailScreenState extends State<PartnerOrderDetailScreen> {
  final _service = PartnerService();
  final _warranty = WarrantyService();

  Order? _order;
  List<WarrantyClaim> _claims = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.orders();
      final order = orders.firstWhere((o) => o.id == widget.orderId,
          orElse: () => orders.first);
      if (mounted) setState(() => _order = order);
    } catch (_) {}
    try {
      final claims = await _warranty.partnerClaims();
      if (mounted) {
        setState(() =>
            _claims = claims.where((c) => c.orderId == widget.orderId).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _run(Future<Order> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
      _toast(ok);
    } catch (e) {
      _toast('$e'.replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderN(widget.orderId))),
      body: _loading && order == null
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(
                  child: Text(l10n.partnerOrderDetailNotFound,
                      style: AppTypography.body))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: _body(order, l10n),
                  ),
                ),
      // Pin the status action to the bottom of the page.
      bottomNavigationBar: order == null ? null : _bottomAction(order, l10n),
    );
  }

  Widget? _bottomAction(Order order, AppLocalizations l10n) {
    final action = _actions(order, l10n);
    if (action == null) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: action,
      ),
    );
  }

  List<Widget> _body(Order order, AppLocalizations l10n) {
    final hasOpenClaim = _claims.any((c) => c.status == 'SUBMITTED');
    return [
      // Header.
      Row(
        children: [
          Expanded(
            child: Text(
              order.isKilo
                  ? l10n.partnerOrderDetailPerKgOrder
                  : l10n.partnerOrderDetailPerItemOrder,
              style: AppTypography.heading2,
            ),
          ),
          StatusChip(status: order.status),
        ],
      ),
      if (hasOpenClaim) ...[
        const SizedBox(height: AppSpacing.sm),
        _warrantyBanner(l10n),
      ],
      if (_partnerVehicleContext(order, l10n) != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _driverVehicleCard(order, _partnerVehicleContext(order, l10n)!, l10n),
      ] else if (_partnerAwaitingDriver(order, l10n) != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _lookingForDriverCard(_partnerAwaitingDriver(order, l10n)!),
      ],
      const SizedBox(height: AppSpacing.xl),

      // Items.
      Text(l10n.partnerOrderDetailItems, style: AppTypography.subheading),
      const SizedBox(height: AppSpacing.sm),
      _card(
        child: Column(
          children: order.items.map((item) {
            final unit = item.isKilo ? 'kg' : 'pcs';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                      child: Text('${item.quantity}$unit ${item.serviceName}',
                          style: AppTypography.body)),
                  if (item.lineTotal != null)
                    Text('Rp ${item.lineTotal!.toStringAsFixed(0)}',
                        style: AppTypography.subheading),
                ],
              ),
            );
          }).toList(),
        ),
      ),

      if (order.pickupAddress.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        _addressRow(order.pickupAddress),
      ],

      // Declared items / intake.
      if (order.declaredItems.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.partnerOrderDetailDeclaredItems,
            style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        _intakeCard(order, l10n),
      ],

      // Progress.
      const SizedBox(height: AppSpacing.xl),
      Text(l10n.partnerOrderDetailProgress, style: AppTypography.subheading),
      const SizedBox(height: AppSpacing.md),
      _card(child: StatusTimeline(order: order)),

      // A contextual "waiting on ..." note for states with no partner action.
      if (_waitingHint(order, l10n) != null) ...[
        const SizedBox(height: AppSpacing.md),
        _hint(_waitingHint(order, l10n)!),
      ],

      // Warranty claims.
      if (_claims.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.partnerOrderDetailWarrantyClaims,
            style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        ..._claims.map((c) => _claimCard(c, l10n)),
      ],

      // Completed summary.
      if (order.status == OrderStatus.completed) ...[
        const SizedBox(height: AppSpacing.xl),
        _completedSummary(order, l10n),
      ],
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  Widget _warrantyBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.ratingStar.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_maybe_outlined,
              size: 16, color: Color(0xFFB07A00)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(l10n.partnerOrderDetailNeedsWarranty,
                style: AppTypography.caption
                    .copyWith(color: const Color(0xFFB07A00))),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined,
            size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTypography.caption)),
      ],
    );
  }

  Widget _intakeCard(Order order, AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...order.declaredItems.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    _declaredThumb(d),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.label, style: AppTypography.body),
                          Row(
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
                              Text(
                                  d.confirmedReceived
                                      ? l10n.partnerOrderDetailReceived
                                      : l10n
                                          .partnerOrderDetailAwaitingAcceptance,
                                  style: AppTypography.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Decode a 'data:image/...;base64,...' URI to bytes, or null.
  Uint8List? _decodePhoto(String dataUri) {
    if (dataUri.isEmpty) return null;
    final comma = dataUri.indexOf(',');
    final b64 = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Build an image for a declared-item photo that may be either a remote URL
  /// (seeded demo items) or a base64 data URI (customer uploads).
  Widget? _declaredImage(String photoUrl, {BoxFit fit = BoxFit.cover}) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http')) {
      return Image.network(fit: fit, photoUrl,
          errorBuilder: (_, __, ___) => const Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: AppColors.textMuted));
    }
    final bytes = _decodePhoto(photoUrl);
    if (bytes == null) return null;
    return Image.memory(bytes, fit: fit);
  }

  Widget _declaredThumb(DeclaredItem d) {
    final image = _declaredImage(d.photoUrl);
    final thumb = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: image ??
          const Icon(Icons.image_not_supported_outlined,
              size: 20, color: AppColors.textMuted),
    );
    if (image == null) return thumb;
    return GestureDetector(
      onTap: () => _viewPhoto(d.photoUrl, d.label),
      child: thumb,
    );
  }

  void _viewPhoto(String photoUrl, String label) {
    final full = _declaredImage(photoUrl, fit: BoxFit.contain);
    if (full == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(child: InteractiveViewer(child: full)),
          ],
        ),
      ),
    );
  }

  /// A note for in-progress states where the partner is just waiting.
  String? _waitingHint(Order order, AppLocalizations l10n) {
    switch (order.status) {
      case OrderStatus.pickedUp:
        return order.isKilo
            ? null
            : l10n.partnerOrderDetailWaitWashAfterPayment;
      case OrderStatus.weighedAwaitingConfirm:
        return l10n.partnerOrderDetailWaitCustomerApprove;
      case OrderStatus.awaitingPayment:
        return l10n.partnerOrderDetailWaitCustomerPay;
      case OrderStatus.driverAssigned:
        return l10n.partnerOrderDetailWaitDriverPickup;
      case OrderStatus.outForDelivery:
        return l10n.partnerOrderDetailOutForDelivery;
      default:
        return null;
    }
  }

  /// The bottom status action for this order, or null when there's nothing for
  /// the partner to do right now (so the bottom bar hides).
  // Returns a heading describing why the driver matters to the laundromat now,
  // or null if the vehicle card shouldn't show in this state.
  String? _partnerVehicleContext(Order order, AppLocalizations l10n) {
    if (order.driver == null) return null;
    switch (order.status) {
      case OrderStatus.pickedUp:
      case OrderStatus.atLaundromat:
        return l10n.partnerOrderDetailDriverBringingIn;
      case OrderStatus.readyForDelivery:
      case OrderStatus.outForDelivery:
        return l10n.partnerOrderDetailDriverTakingOut;
      default:
        return null;
    }
  }

  // "Looking for a driver" state for the partner: the laundry is ready to ship
  // but no driver has accepted the delivery leg yet.
  String? _partnerAwaitingDriver(Order order, AppLocalizations l10n) {
    if (order.driver != null) return null;
    if (order.status == OrderStatus.readyForDelivery) {
      return l10n.partnerOrderDetailLookingForDriver;
    }
    return null;
  }

  Widget _lookingForDriverCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTypography.body)),
        ],
      ),
    );
  }

  Widget _driverVehicleCard(Order order, String heading, AppLocalizations l10n) {
    final d = order.driver!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.two_wheeler,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  d.plateNumber.isNotEmpty
                      ? d.plateNumber
                      : l10n.partnerOrderDetailVehicleFallback,
                  style: AppTypography.heading2,
                ),
                Text(
                  [
                    if (d.vehicleType.isNotEmpty) d.vehicleType,
                    if (d.name != null && d.name!.isNotEmpty) d.name,
                  ].join(' · '),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _actions(Order order, AppLocalizations l10n) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (order.status) {
      case OrderStatus.pendingAcceptance:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _run(() => _service.reject(order.id),
                    l10n.partnerOrderDetailOrderRejected),
                child: Text(l10n.partnerOrderDetailReject),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48)),
                onPressed: () => _run(() => _service.accept(order.id),
                    l10n.partnerOrderDetailOrderAccepted),
                child: Text(l10n.partnerOrderDetailAccept),
              ),
            ),
          ],
        );
      case OrderStatus.atLaundromat:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _promptReceive(order, l10n),
            icon: Icon(order.isKilo
                ? Icons.scale_outlined
                : Icons.inventory_2_outlined),
            label: Text(order.isKilo
                ? l10n.partnerOrderDetailReceiveAndWeigh
                : l10n.partnerOrderDetailConfirmReceived),
          ),
        );
      case OrderStatus.washing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _run(() => _service.markReady(order.id),
                l10n.partnerOrderDetailMarkedReady),
            icon: const Icon(Icons.check),
            label: Text(l10n.partnerOrderDetailMarkReady),
          ),
        );
      default:
        return null;
    }
  }

  // Combined "receive & weigh" sheet shown at AT_LAUNDROMAT: the partner checks
  // off each declared item as received (or flags a discrepancy) and, for per-kg
  // orders, enters the measured weight — all submitted in one action.
  Future<void> _promptReceive(Order order, AppLocalizations l10n) async {
    final isKilo = order.isKilo;
    final weightCtrl = TextEditingController();
    // Per declared item: received flag + optional discrepancy note controller.
    final received = {for (final d in order.declaredItems) d.id: true};
    final noteCtrls = {
      for (final d in order.declaredItems) d.id: TextEditingController()
    };

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom: AppSpacing.lg + bottomInset,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      isKilo
                          ? l10n.partnerOrderDetailReceiveAndWeigh
                          : l10n.partnerOrderDetailConfirmReceived,
                      style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    order.declaredItems.isEmpty
                        ? l10n.partnerOrderDetailConfirmArrived
                        : l10n.partnerOrderDetailConfirmEachItem,
                    style: AppTypography.caption,
                  ),
                  if (order.declaredItems.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.partnerOrderDetailDeclaredItems,
                        style: AppTypography.subheading),
                    const SizedBox(height: AppSpacing.xs),
                    ...order.declaredItems.map((d) {
                      final ok = received[d.id] ?? true;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: ok,
                            activeColor: AppColors.primary,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            title: Text(d.label, style: AppTypography.body),
                            subtitle: Text(
                                ok
                                    ? l10n.partnerOrderDetailReceived
                                    : l10n.partnerOrderDetailNotReceived,
                                style: AppTypography.caption.copyWith(
                                  color: ok
                                      ? AppColors.success
                                      : AppColors.error,
                                )),
                            onChanged: (v) =>
                                setSheet(() => received[d.id] = v ?? false),
                          ),
                          if (!ok)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: TextField(
                                controller: noteCtrls[d.id],
                                decoration: InputDecoration(
                                  labelText:
                                      l10n.partnerOrderDetailDiscrepancyHint,
                                  isDense: true,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                  if (isKilo) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.partnerOrderDetailMeasuredWeight,
                        style: AppTypography.subheading),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: weightCtrl,
                      autofocus: order.declaredItems.isEmpty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.partnerOrderDetailWeightLabel,
                        suffixText: 'kg',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isKilo) {
                          final kg = double.tryParse(weightCtrl.text.trim());
                          if (kg == null || kg <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(l10n
                                      .partnerOrderDetailEnterValidWeight)),
                            );
                            return;
                          }
                        }
                        Navigator.pop(ctx, {
                          'weighedKg': isKilo
                              ? double.tryParse(weightCtrl.text.trim())
                              : null,
                          'intake': order.declaredItems.map((d) {
                            final ok = received[d.id] ?? true;
                            return {
                              'declaredItemId': d.id,
                              'confirmed': ok,
                              if (!ok)
                                'discrepancyNote':
                                    noteCtrls[d.id]?.text.trim() ?? '',
                            };
                          }).toList(),
                        });
                      },
                      child: Text(isKilo
                          ? l10n.partnerOrderDetailSubmitWeight
                          : l10n.partnerOrderDetailConfirmStartWashing),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;
    final weighedKg = result['weighedKg'] as double?;
    final intake =
        (result['intake'] as List).cast<Map<String, dynamic>>();
    await _run(
      () => _service.receive(order.id, weighedKg: weighedKg, intake: intake),
      isKilo
          ? l10n.partnerOrderDetailWeightRecorded
          : l10n.partnerOrderDetailOrderReceived,
    );
  }

  Widget _claimCard(WarrantyClaim c, AppLocalizations l10n) {
    final busy = _busy;
    final open = c.status == 'SUBMITTED';
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
              Expanded(
                child: Text(
                    c.declaredItem?.label ??
                        l10n.orderDetailItemFallback(c.declaredItemId),
                    style: AppTypography.subheading),
              ),
              Text(c.status, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(c.description, style: AppTypography.body),
          if (c.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: c.photoUrls.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final bytes = _decodePhoto(c.photoUrls[i]);
                  if (bytes == null) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.broken_image_outlined,
                          size: 18, color: AppColors.textMuted),
                    );
                  }
                  return GestureDetector(
                    onTap: () => _viewPhoto(
                        c.photoUrls[i], l10n.partnerOrderDetailClaimPhoto),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.memory(bytes,
                          width: 56, height: 56, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          if (open) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: busy ? null : () => _resolveClaim(c, 'REJECTED'),
                    child: Text(l10n.partnerOrderDetailReject),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                    onPressed: busy ? null : () => _resolveClaim(c, 'APPROVED'),
                    child: Text(l10n.partnerOrderDetailApprove),
                  ),
                ),
              ],
            ),
          ] else if (c.resolutionNote != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                  l10n.partnerOrderDetailResolutionNote(c.resolutionNote!),
                  style: AppTypography.caption),
            ),
        ],
      ),
    );
  }

  Future<void> _resolveClaim(WarrantyClaim c, String status) async {
    final l10n = AppLocalizations.of(context);
    final noteCtrl = TextEditingController();
    final payoutCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.partnerOrderDetailResolveTitle(status),
            style: AppTypography.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                  labelText: l10n.partnerOrderDetailResolutionNoteLabel),
              maxLines: 2,
            ),
            if (status != 'REJECTED') ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: payoutCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: l10n.partnerOrderDetailPayoutLabel,
                    prefixText: 'Rp '),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: Text(l10n.commonCancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _warranty.resolveClaim(
        c.id,
        status: status,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        payoutAmount: status == 'REJECTED'
            ? null
            : double.tryParse(payoutCtrl.text.trim()),
      );
      if (!mounted) return;
      await _load();
      _toast(status == 'REJECTED'
          ? l10n.partnerOrderDetailClaimRejected
          : l10n.partnerOrderDetailClaimApproved);
    } catch (e) {
      _toast('$e'.replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _completedSummary(Order order, AppLocalizations l10n) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(l10n.partnerOrderDetailDeliveredCompleted,
                style: AppTypography.body),
          ),
          if (order.finalTotal != null)
            Text('Rp ${order.finalTotal!.toStringAsFixed(0)}',
                style: AppTypography.price),
        ],
      ),
    );
  }

  Widget _hint(String text) => Container(
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
            Expanded(child: Text(text, style: AppTypography.caption)),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}
