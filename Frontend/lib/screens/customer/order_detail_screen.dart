import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/payment_launcher.dart';
import '../../models/order.dart';
import '../../models/warranty.dart';
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
    setState(() => _future = _service.getOrder(widget.orderId));
  }

  Future<void> _approveWeight(Order order) async {
    setState(() => _approving = true);
    try {
      await _service.approveWeight(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price approved. Proceed to payment.'),
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
    setState(() => _paying = true);
    try {
      final result = await _paymentLauncher.launch(order.id);
      if (!mounted) return;
      final msg = switch (result) {
        PaymentResult.success => 'Payment received.',
        PaymentResult.pending => 'Payment pending confirmation.',
        PaymentResult.error => 'Payment failed. You can try again.',
        PaymentResult.closed => 'Payment window closed.',
        PaymentResult.launched =>
          'Payment opened. This order updates once confirmed.',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
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
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _header(order),
                const SizedBox(height: AppSpacing.xl),
                if (order.needsWeightApproval) ...[
                  _weighApprovalCard(order),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (order.status == OrderStatus.awaitingPayment) ...[
                  _payCard(order),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text('Progress', style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.md),
                _card(child: StatusTimeline(order: order)),
                const SizedBox(height: AppSpacing.xl),
                Text('Receipt', style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.md),
                _receiptCard(order),
                if (order.declaredItems.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text('Declared items', style: AppTypography.subheading),
                  const SizedBox(height: AppSpacing.md),
                  _declaredCard(order),
                ],
                if (order.status == OrderStatus.completed &&
                    order.declaredItems.any((d) => d.confirmedReceived)) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _warrantySection(order),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(Order order) {
    return Row(
      children: [
        const Icon(Icons.local_laundry_service, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.laundromat?.name ?? 'Laundromat',
                  style: AppTypography.heading2),
              Text('Order #${order.id}', style: AppTypography.caption),
            ],
          ),
        ),
        StatusChip(status: order.status),
      ],
    );
  }

  Widget _weighApprovalCard(Order order) {
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
          Text('Confirm your weighed price', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.sm),
          if (kg != null)
            _row('Measured weight', '${kg.toStringAsFixed(1)} kg'),
          if (total != null)
            _row('Final price', 'Rp ${total.toStringAsFixed(0)}'),
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
                  : const Text('Approve & continue to payment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payCard(Order order) {
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
          Text('Payment required', style: AppTypography.heading2),
          const SizedBox(height: AppSpacing.sm),
          if (total != null) _row('Amount due', 'Rp ${total.toStringAsFixed(0)}'),
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
                  : const Text('Pay now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(Order order) {
    final payment = order.latestPayment;
    return _card(
      child: Column(
        children: [
          ...order.items.map((item) {
            final unit = item.isKilo ? 'kg' : 'pcs';
            final right = item.lineTotal != null
                ? 'Rp ${item.lineTotal!.toStringAsFixed(0)}'
                : (item.isKilo ? 'Weighed' : '—');
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
            _row('Subtotal', 'Rp ${order.itemsSubtotal!.toStringAsFixed(0)}'),
          _row('Delivery fee', 'Rp ${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.voucherDiscount > 0)
            _row('Voucher',
                '- Rp ${order.voucherDiscount.toStringAsFixed(0)}'),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand total', style: AppTypography.heading2),
              Text(
                order.finalTotal != null
                    ? 'Rp ${order.finalTotal!.toStringAsFixed(0)}'
                    : 'After weighing',
                style: AppTypography.heading2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _row('Payment', payment?.status ?? 'Not started'),
        ],
      ),
    );
  }

  Widget _declaredCard(Order order) {
    return _card(
      child: Column(
        children: order.declaredItems.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(
                  d.confirmedReceived
                      ? Icons.verified
                      : Icons.hourglass_empty,
                  size: 16,
                  color: d.confirmedReceived
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(d.label, style: AppTypography.body)),
                Text(
                  d.confirmedReceived ? 'Confirmed' : 'Pending intake',
                  style: AppTypography.caption,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _warrantySection(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Warranty', style: AppTypography.subheading),
            ),
            TextButton.icon(
              onPressed: () => _startClaim(order),
              icon: const Icon(Icons.gpp_maybe_outlined, size: 18),
              label: const Text('File a claim'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FutureBuilder<List<WarrantyClaim>>(
          future: _warranty.orderClaims(order.id),
          builder: (context, snapshot) {
            final claims = snapshot.data ?? [];
            if (claims.isEmpty) {
              return Text(
                'You can file a claim against a confirmed declared item if something went wrong.',
                style: AppTypography.caption,
              );
            }
            return Column(
              children: claims.map((c) => _claimCard(c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _claimCard(WarrantyClaim c) {
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
                child: Text(c.declaredItem?.label ?? 'Item #${c.declaredItemId}',
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
            Text('Resolution: ${c.resolutionNote}', style: AppTypography.caption),
          ],
          if (c.payoutAmount != null)
            Text('Payout: Rp ${c.payoutAmount!.toStringAsFixed(0)} (Washly)',
                style: AppTypography.caption),
        ],
      ),
    );
  }

  Future<void> _startClaim(Order order) async {
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
                  const SnackBar(
                      content: Text('Pick an item and describe the issue.')),
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
                  const Text('File a warranty claim',
                      style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<int>(
                    initialValue: selectedItemId,
                    decoration: const InputDecoration(labelText: 'Item'),
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
                    decoration: const InputDecoration(
                      labelText: 'What went wrong?',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: submitting ? null : addPhoto,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Add photo'),
                      ),
                      if (photos.isNotEmpty)
                        Text('${photos.length} attached',
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
                          : const Text('Submit claim'),
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
        const SnackBar(
          content: Text('Claim submitted.'),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
