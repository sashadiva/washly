import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/payment_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../models/warranty.dart';
import '../../services/laundromat_service.dart';
import '../../services/order_service.dart';
import '../../services/warranty_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';

/// Full order view: lifecycle timeline, per-kg weigh-in approval action, and
/// the receipt (line items, fee, voucher, payment status, totals).
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  final _warranty = WarrantyService();
  final _laundromats = LaundromatService();
  final _paymentLauncher = PaymentLauncher();
  final _picker = ImagePicker();
  late Future<Order> _future;
  bool _approving = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getOrder(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = _service.getOrder(widget.orderId);
    });
  }

  Future<void> _approveWeight(Order order) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _approving = true);
    try {
      await _service.approveWeight(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderDetailPriceApprovedToast),
          backgroundColor: AppColors.success,
        ),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _pay(Order order) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _paying = true);
    try {
      final result = await _paymentLauncher.launch(order.id);
      if (!mounted) return;
      final msg = switch (result) {
        PaymentResult.success => l10n.orderDetailPaymentReceived,
        PaymentResult.pending => l10n.orderDetailPaymentPending,
        PaymentResult.error => l10n.orderDetailPaymentFailed,
        PaymentResult.closed => l10n.orderDetailPaymentClosed,
        PaymentResult.launched => l10n.orderDetailPaymentLaunched,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
      );
      // Give the webhook a moment, then refresh; also poll in the background.
      _reload();
      _paymentLauncher.awaitSettlement(order.id).then((_) {
        if (mounted) _reload();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailTitle)),
      body: FutureBuilder<Order>(
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
          final order = snapshot.data!;
          final vehicleContext = _customerVehicleContext(l10n, order);
          final awaitingDriver = _customerAwaitingDriver(l10n, order);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _header(l10n, order),
                const SizedBox(height: AppSpacing.xl),
                if (vehicleContext != null) ...[
                  _driverVehicleCard(l10n, order, vehicleContext),
                  const SizedBox(height: AppSpacing.xl),
                ] else if (awaitingDriver != null) ...[
                  _lookingForDriverCard(awaitingDriver),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (order.needsWeightApproval) ...[
                  _weighApprovalCard(l10n, order),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (order.status == OrderStatus.awaitingPayment) ...[
                  _payCard(l10n, order),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text(l10n.orderDetailProgress, style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.md),
                _card(child: StatusTimeline(order: order)),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.orderDetailReceipt, style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.md),
                _receiptCard(l10n, order),
                if (order.declaredItems.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.orderDetailDeclaredItems,
                      style: AppTypography.subheading),
                  const SizedBox(height: AppSpacing.md),
                  _declaredCard(l10n, order),
                ],
                if (order.status == OrderStatus.completed) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _completedActions(l10n, order),
                ],
                if (order.status == OrderStatus.completed &&
                    order.declaredItems.any((d) => d.confirmedReceived)) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _warrantyClaimsList(l10n, order),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Returns a short heading describing why the driver matters right now, or
  // null if the vehicle card shouldn't show for the customer in this state.
  String? _customerVehicleContext(AppLocalizations l10n, Order order) {
    if (order.driver == null) return null;
    switch (order.status) {
      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
        return l10n.orderDetailDriverPickingUp;
      case OrderStatus.outForDelivery:
        return l10n.orderDetailDriverDelivering;
      default:
        return null;
    }
  }

  // "Looking for a driver" states for the customer: an offer is out but no
  // driver has accepted yet (pickup pending after accept, delivery pending
  // after the laundromat marks ready).
  String? _customerAwaitingDriver(AppLocalizations l10n, Order order) {
    if (order.driver != null) return null;
    switch (order.status) {
      case OrderStatus.accepted:
        return l10n.orderDetailLookingForPickup;
      case OrderStatus.readyForDelivery:
        return l10n.orderDetailLookingForDelivery;
      default:
        return null;
    }
  }

  Widget _driverVehicleCard(AppLocalizations l10n, Order order, String heading) {
    final d = order.driver!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          Row(
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
                    Text(
                      d.plateNumber.isNotEmpty
                          ? d.plateNumber
                          : l10n.orderDetailVehicleFallback,
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
        ],
      ),
    );
  }

  // Shown while an offer is out but no driver has accepted yet.
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

  Widget _header(AppLocalizations l10n, Order order) {
    return Row(
      children: [
        const Icon(Icons.local_laundry_service, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.laundromat?.name ?? l10n.orderDetailLaundromatFallback,
                  style: AppTypography.heading2),
              Text(l10n.orderN(order.id), style: AppTypography.caption),
            ],
          ),
        ),
        StatusChip(status: order.status),
      ],
    );
  }

  Widget _weighApprovalCard(AppLocalizations l10n, Order order) {
    final kg = order.weighedKg;
    final total = order.finalTotal;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.orderDetailConfirmWeighedPrice, style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.orderDetailWeighedExplainer,
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.md),

          // Declared-items receipt confirmation (the warranty side).
          if (order.declaredItems.isNotEmpty) ...[
            _declaredIntakeSummary(l10n, order),
            const SizedBox(height: AppSpacing.md),
          ],

          // Price breakdown.
          if (kg != null)
            _row(l10n.orderDetailMeasuredWeight,
                l10n.orderDetailKg(kg.toStringAsFixed(1))),
          if (order.itemsSubtotal != null)
            _row(l10n.orderDetailWashSubtotal,
                l10n.moneyRp(order.itemsSubtotal!.toStringAsFixed(0))),
          _row(l10n.orderDetailDeliveryFee,
              l10n.moneyRp(order.deliveryFee.toStringAsFixed(0))),
          if (order.declaredItemsFee > 0)
            _row(l10n.orderDetailDeclaredProtection,
                l10n.moneyRp(order.declaredItemsFee.toStringAsFixed(0))),
          if (order.voucherDiscount > 0)
            _row(l10n.orderDetailVoucher,
                l10n.moneyRpNegative(order.voucherDiscount.toStringAsFixed(0))),
          const Divider(height: AppSpacing.lg, color: AppColors.primary),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.orderDetailFinalPrice, style: AppTypography.heading2),
              Text(
                total != null ? l10n.moneyRp(total.toStringAsFixed(0)) : '—',
                style:
                    AppTypography.heading2.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _approving ? null : () => _approveWeight(order),
              child: _approving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l10n.orderDetailApproveContinue),
            ),
          ),
        ],
      ),
    );
  }

  // Shows how the laundromat received the customer's declared items (received
  // vs flagged discrepancy) so warranty confirmation sits with price approval.
  Widget _declaredIntakeSummary(AppLocalizations l10n, Order order) {
    final received = order.declaredItems.where((d) => d.confirmedReceived).length;
    final total = order.declaredItems.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.orderDetailDeclaredReceived(received, total),
                  style: AppTypography.subheading),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...order.declaredItems.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      d.confirmedReceived
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 14,
                      color: d.confirmedReceived
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                        child: Text(d.label, style: AppTypography.caption)),
                    if (!d.confirmedReceived)
                      Text(
                        d.discrepancyNote?.isNotEmpty == true
                            ? d.discrepancyNote!
                            : l10n.orderDetailNotReceived,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.error),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _payCard(AppLocalizations l10n, Order order) {
    final total = order.finalTotal;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.orderDetailPaymentRequired, style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.sm),
          if (total != null)
            _row(l10n.orderDetailAmountDue,
                l10n.moneyRp(total.toStringAsFixed(0))),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _paying ? null : () => _pay(order),
              child: _paying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l10n.orderDetailPayNow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(AppLocalizations l10n, Order order) {
    final payment = order.latestPayment;
    return _card(
      child: Column(
        children: [
          ...order.items.map((item) {
            final unit = item.isKilo
                ? l10n.orderDetailUnitKg
                : l10n.orderDetailUnitPcs;
            final right = item.lineTotal != null
                ? l10n.moneyRp(item.lineTotal!.toStringAsFixed(0))
                : (item.isKilo ? l10n.orderDetailWeighed : '—');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.quantity}$unit x ',
                      style: AppTypography.subheading),
                  Expanded(
                      child: Text(item.serviceName, style: AppTypography.body)),
                  Text(right, style: AppTypography.body),
                ],
              ),
            );
          }),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          if (order.itemsSubtotal != null)
            _row(l10n.orderDetailSubtotal,
                l10n.moneyRp(order.itemsSubtotal!.toStringAsFixed(0))),
          _row(l10n.orderDetailDeliveryFee,
              l10n.moneyRp(order.deliveryFee.toStringAsFixed(0))),
          if (order.declaredItemsFee > 0)
            _row(l10n.orderDetailDeclaredProtection,
                l10n.moneyRp(order.declaredItemsFee.toStringAsFixed(0))),
          if (order.voucherDiscount > 0)
            _row(l10n.orderDetailVoucher,
                l10n.moneyRpNegative(order.voucherDiscount.toStringAsFixed(0))),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.orderDetailGrandTotal, style: AppTypography.heading2),
              Text(
                order.finalTotal != null
                    ? l10n.moneyRp(order.finalTotal!.toStringAsFixed(0))
                    : l10n.orderDetailAfterWeighing,
                style: AppTypography.heading2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _row(l10n.orderDetailPayment,
              payment?.status ?? l10n.orderDetailPaymentNotStarted),
        ],
      ),
    );
  }

  Widget _declaredCard(AppLocalizations l10n, Order order) {
    return _card(
      child: Column(
        children: order.declaredItems.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                _declaredThumb(d),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(d.label, style: AppTypography.body)),
                Row(
                  children: [
                    Icon(
                      d.confirmedReceived
                          ? Icons.verified
                          : Icons.hourglass_empty,
                      size: 14,
                      color: d.confirmedReceived
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      d.confirmedReceived
                          ? l10n.orderDetailReceived
                          : l10n.orderDetailAwaitingIntake,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

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
              size: 18,
              color: AppColors.textMuted));
    }
    final bytes = _decodePhoto(photoUrl);
    if (bytes == null) return null;
    return Image.memory(bytes, fit: fit);
  }

  Widget _declaredThumb(DeclaredItem d) {
    final image = _declaredImage(d.photoUrl);
    final thumb = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: image ??
          const Icon(Icons.image_not_supported_outlined,
              size: 18, color: AppColors.textMuted),
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

  // Two actions shown once the order is completed: rate the laundromat, and
  // open the warranty flow for declared items.
  Widget _completedActions(AppLocalizations l10n, Order order) {
    final hasWarranty = order.declaredItems.any((d) => d.confirmedReceived);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.orderDetailHowDidItGo, style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(order),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text(l10n.orderDetailRateLaundromat),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasWarranty ? () => _showWarrantyDialog(order) : null,
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: Text(l10n.orderDetailWarranty),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
        if (!hasWarranty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.orderDetailWarrantyOnlyDeclared,
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  // The list of warranty claims already filed on this order.
  Widget _warrantyClaimsList(AppLocalizations l10n, Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.orderDetailWarrantyClaims, style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.xs),
        FutureBuilder<List<WarrantyClaim>>(
          future: _warranty.orderClaims(order.id),
          builder: (context, snapshot) {
            final claims = snapshot.data ?? [];
            if (claims.isEmpty) {
              return Text(
                l10n.orderDetailNoClaims,
                style: AppTypography.caption,
              );
            }
            return Column(
              children: claims.map((c) => _claimCard(l10n, c)).toList(),
            );
          },
        ),
      ],
    );
  }

  // Popup: rate the laundromat (stars + optional comment).
  void _showRatingDialog(Order order) {
    final l10n = AppLocalizations.of(context);
    final storeId = order.laundromat?.id;
    if (storeId == null) return;
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.orderDetailRateThisLaundromat,
              textAlign: TextAlign.center, style: AppTypography.heading2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(order.laundromat?.name ?? l10n.orderDetailLaundromatFallback,
                  style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < selectedRating ? Icons.star : Icons.star_border,
                      color: AppColors.ratingStar,
                    ),
                    onPressed: () =>
                        setDlg(() => selectedRating = idx + 1),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: l10n.orderDetailAddCommentOptional),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = context.read<AuthStore>().currentUser?.id;
                final messenger = ScaffoldMessenger.of(context);
                if (userId == null) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(l10n.orderDetailSignInToRate)));
                  return;
                }
                try {
                  await _laundromats.addReview(
                    laundromatId: storeId,
                    userId: userId,
                    rating: selectedRating,
                    comment: commentCtrl.text.trim(),
                  );
                  if (dctx.mounted) Navigator.pop(dctx);
                  messenger.showSnackBar(SnackBar(
                    content: Text(l10n.orderDetailRatingThanks),
                    backgroundColor: AppColors.success,
                  ));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(
                    content: Text('$e'.replaceFirst('Exception: ', '')),
                    backgroundColor: AppColors.error,
                  ));
                }
              },
              child: Text(l10n.commonSubmit),
            ),
          ],
        ),
      ),
    );
  }

  // Popup: confirm the customer wants to take warranty over declared items,
  // then open the claim flow.
  void _showWarrantyDialog(Order order) {
    final l10n = AppLocalizations.of(context);
    final confirmedItems =
        order.declaredItems.where((d) => d.confirmedReceived).toList();
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.orderDetailUseWarrantyTitle,
            style: AppTypography.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orderDetailWarrantyExplainer,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.orderDetailCoveredItems, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.xs),
            ...confirmedItems.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(d.label, style: AppTypography.body)),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(l10n.commonNotNow),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dctx);
              _startClaim(order);
            },
            child: Text(l10n.orderDetailFileClaim),
          ),
        ],
      ),
    );
  }

  Widget _claimCard(AppLocalizations l10n, WarrantyClaim c) {
    Color statusColor;
    switch (c.status) {
      case 'APPROVED':
      case 'RESOLVED':
        statusColor = AppColors.success;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primaryDark;
    }
    return _card(
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
              Text(c.status,
                  style: AppTypography.caption.copyWith(color: statusColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(c.description, style: AppTypography.body),
          if (c.resolutionNote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.orderDetailResolution(c.resolutionNote!),
                style: AppTypography.caption),
          ],
          if (c.payoutAmount != null)
            Text(l10n.orderDetailPayout(c.payoutAmount!.toStringAsFixed(0)),
                style: AppTypography.caption),
        ],
      ),
    );
  }

  Future<void> _startClaim(Order order) async {
    final l10n = AppLocalizations.of(context);
    final confirmedItems =
        order.declaredItems.where((d) => d.confirmedReceived).toList();
    if (confirmedItems.isEmpty) return;

    int? selectedItemId = confirmedItems.first.id;
    final descCtrl = TextEditingController();
    final photos = <String>[];

    final filed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> addPhoto() async {
              final file = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                imageQuality: 70,
              );
              if (file == null) return;
              final bytes = await file.readAsBytes();
              setSheet(() =>
                  photos.add('data:image/jpeg;base64,${base64Encode(bytes)}'));
            }

            Future<void> submit() async {
              if (selectedItemId == null || descCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(l10n.orderDetailPickItemDescribe)),
                );
                return;
              }
              setSheet(() => submitting = true);
              try {
                await _warranty.fileClaim(
                  orderId: order.id,
                  declaredItemId: selectedItemId!,
                  description: descCtrl.text.trim(),
                  photoUrls: photos,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                setSheet(() => submitting = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('$e'.replaceFirst('Exception: ', '')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.orderDetailFileClaimTitle,
                      style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<int>(
                    initialValue: selectedItemId,
                    decoration: InputDecoration(labelText: l10n.orderDetailItem),
                    items: confirmedItems
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.label),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedItemId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.orderDetailWhatWentWrong,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: submitting ? null : addPhoto,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: Text(l10n.orderDetailAddPhoto),
                      ),
                      if (photos.isNotEmpty)
                        Text(l10n.orderDetailPhotosAttached(photos.length),
                            style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(l10n.orderDetailSubmitClaim),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (filed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderDetailClaimSubmitted),
          backgroundColor: AppColors.success,
        ),
      );
      _reload();
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body),
          Text(value, style: AppTypography.subheading),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child:
            Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
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
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context).commonRetry)),
          ],
        ),
      ),
    );
  }
}
