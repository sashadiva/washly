import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/auth_store.dart';
import 'package:provider/provider.dart';
import '../core/cart_store.dart';
import '../l10n/app_localizations.dart';
import '../core/payment_launcher.dart';
import '../models/cart_item.dart';
import '../models/laundromat_detail.dart';
import '../models/order.dart';
import '../models/wallet.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'customer/voucher_select_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final LaundromatDetail store;
  final List<CartItem> cart;

  const CheckoutScreen({super.key, required this.store, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

/// A declared item the customer captured at checkout (label + local photo).
class _DeclaredDraft {
  final String label;
  final String photoDataUri;
  _DeclaredDraft({required this.label, required this.photoDataUri});
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _service = OrderService();
  final _paymentLauncher = PaymentLauncher();
  final _picker = ImagePicker();
  final _addressCtrl =
      TextEditingController(text: 'Jl. Rawa Belong No. 15, Palmerah');
  final _notesCtrl = TextEditingController();
  final List<_DeclaredDraft> _declared = [];
  Voucher? _voucher; // applied voucher, if any
  bool _isSubmitting = false;

  // Flat protection fee charged once when the order carries declared items.
  static const double _declaredItemsFee = 2000;

  double get _voucherDiscount => _voucher?.amountOff ?? 0;

  // Per-item total shown before the delivery fee (which is computed at pickup):
  // wash subtotal + declared-items fee - voucher, floored at 0. Mirrors the
  // backend's finalTotal formula (minus the delivery fee component).
  double _perItemTotalBeforeDeliveryFee() {
    final gross =
        subtotal + (_hasDeclaredItems ? _declaredItemsFee : 0) - _voucherDiscount;
    return gross < 0 ? 0 : gross;
  }

  // Per-kg orders have no known total up front; the price is finalized after
  // the partner weighs the laundry.
  bool get _isPerKg => widget.cart.any((i) => i.isKilo);

  bool get _hasDeclaredItems => _declared.isNotEmpty;

  double get subtotal =>
      widget.cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _addDeclaredItem() async {
    final l10n = AppLocalizations.of(context);
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 70,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              l10n.checkoutPickerError('$e'.replaceFirst('Exception: ', ''))),
          backgroundColor: AppColors.error,
        ));
      }
      return;
    }
    if (file == null) return; // user cancelled

    final bytes = await file.readAsBytes();
    final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    if (!mounted) return;
    final labelCtrl = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.checkoutLabelItemTitle, style: AppTypography.heading2),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.checkoutLabelItemHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, labelCtrl.text.trim()),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );

    if (label == null || label.isEmpty) return;
    setState(() {
      _declared.add(_DeclaredDraft(label: label, photoDataUri: dataUri));
    });
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context);
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutEnterPickupAddress)),
      );
      return;
    }

    final auth = context.read<AuthStore>();
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutSignInToOrder)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await _service.createOrder(
        laundromatId: widget.store.id,
        pickupAddress: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        cart: widget.cart,
        declaredItems: _declared
            .map((d) =>
                DeclaredItemInput(label: d.label, photoUrl: d.photoDataUri))
            .toList(),
        voucherId: _voucher?.id,
      );

      if (!mounted) return;

      // Order placed — empty the global cart so it doesn't linger.
      context.read<CartStore>().clear();

      // Per-item orders are paid up front, before the partner accepts. Per-kg
      // orders are paid later, after the laundry is weighed and the customer
      // approves the price.
      if (order.isKilo) {
        _showPerKgPlaced(order);
      } else {
        await _payPerItem(order);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Per-item: open the Snap popup (web) and reflect the reported outcome.
  Future<void> _payPerItem(Order order) async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await _paymentLauncher.launch(order.id);
      if (!mounted) return;
      switch (result) {
        case PaymentResult.success:
          _showResultDialog(
            title: l10n.checkoutPaymentReceivedTitle,
            message: l10n.checkoutPaymentReceivedBody,
          );
          break;
        case PaymentResult.pending:
          _showResultDialog(
            title: l10n.checkoutPaymentPendingTitle,
            message: l10n.checkoutPaymentPendingBody,
          );
          break;
        case PaymentResult.closed:
          _showResultDialog(
            title: l10n.checkoutPaymentNotCompletedTitle,
            message: l10n.checkoutPaymentNotCompletedBody,
          );
          break;
        case PaymentResult.error:
          _showResultDialog(
            title: l10n.checkoutPaymentFailedTitle,
            message: l10n.checkoutPaymentFailedBody,
          );
          break;
        case PaymentResult.launched:
          _showResultDialog(
            title: l10n.checkoutCompletePaymentTitle,
            message: l10n.checkoutCompletePaymentBody,
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: l10n.checkoutOrderPlacedTitle,
        message: l10n.checkoutOrderPlacedPaymentError(
            '$e'.replaceFirst('Exception: ', '')),
      );
    }
  }

  void _showPerKgPlaced(Order order) {
    final l10n = AppLocalizations.of(context);
    _showResultDialog(
      title: l10n.checkoutPerKgPlacedTitle,
      message: l10n.checkoutPerKgPlacedBody,
    );
  }

  void _showResultDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTypography.heading2),
        content: Text(message, style: AppTypography.body),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // leave checkout
              Navigator.pop(context); // leave detail -> back to discovery
            },
            child: Text(AppLocalizations.of(ctx).commonDone),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text(value, style: AppTypography.subheading),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(widget.store.name, style: AppTypography.heading2),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xxl, color: AppColors.border),

            Text(l10n.checkoutDeliveryPickupDetails,
                style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: l10n.checkoutPickupAddressLabel,
                prefixIcon: const Icon(Icons.location_on, color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: l10n.checkoutNotesLabel,
                hintText: l10n.checkoutNotesHint,
                prefixIcon:
                    const Icon(Icons.notes, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Text(l10n.checkoutOrderSummary, style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.md),
            _orderSummaryCard(l10n),

            const SizedBox(height: AppSpacing.lg),
            _declaredItemsCard(l10n),

            const SizedBox(height: AppSpacing.lg),
            _voucherCard(l10n),

            const SizedBox(height: AppSpacing.lg),
            _priceCard(l10n),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _placeOrder,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.checkoutPlaceOrder,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
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
        child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
      );

  Widget _orderSummaryCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        children: widget.cart.map((item) {
          // Per-kg has no customer-set quantity (weighed at the laundromat), so
          // show a scale marker instead of a piece count.
          final qtyLabel =
              item.isKilo ? '⚖  ' : l10n.checkoutPiecesPrefix(item.quantity);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(qtyLabel, style: AppTypography.subheading),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.serviceName, style: AppTypography.subheading),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Text(item.notes!, style: AppTypography.caption),
                    ],
                  ),
                ),
                Text(
                  item.isKilo
                      ? l10n.checkoutPricePerKg(item.unitPrice.toStringAsFixed(0))
                      : l10n.moneyRp(item.totalPrice.toStringAsFixed(0)),
                  style: AppTypography.body,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _declaredItemsCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(l10n.checkoutDeclaredItemsOptional,
                    style: AppTypography.subheading),
              ),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _addDeclaredItem,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(l10n.commonAdd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.checkoutDeclaredExplainer,
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Benefit explanation.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 16, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.checkoutDeclaredBenefit,
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Fee note.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.checkoutDeclaredFeeNote(
                      _declaredItemsFee.toStringAsFixed(0)),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (_declared.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ..._declared.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(d.label, style: AppTypography.body)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textMuted,
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _declared.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _voucherCard(AppLocalizations l10n) {
    final applied = _voucher != null;
    return InkWell(
      onTap: _isSubmitting ? null : _openVoucherSelect,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: _card(
        child: Row(
          children: [
            Icon(Icons.confirmation_number_outlined,
                color: applied ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(applied ? l10n.checkoutVoucherApplied : l10n.checkoutApplyVoucher,
                      style: AppTypography.subheading),
                  if (applied)
                    Text(l10n.moneyRpOff(_voucher!.amountOff.toStringAsFixed(0)),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.success)),
                ],
              ),
            ),
            if (applied)
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => setState(() => _voucher = null),
                child: Text(l10n.commonRemove),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openVoucherSelect() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => VoucherSelectScreen(selectedVoucherId: _voucher?.id),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result == 'none') {
        _voucher = null;
      } else if (result is Voucher) {
        _voucher = result;
      }
    });
  }

  Widget _priceCard(AppLocalizations l10n) {
    return _card(
      child: Column(
        children: [
          _summaryRow(
            _isPerKg ? l10n.checkoutEstimatedWashPerKg : l10n.checkoutWashSubtotal,
            _isPerKg
                ? l10n.checkoutWeighedAtPickup
                : l10n.moneyRp(subtotal.toStringAsFixed(0)),
          ),
          if (_hasDeclaredItems) ...[
            const SizedBox(height: AppSpacing.sm),
            _summaryRow(
              l10n.checkoutDeclaredProtection,
              l10n.moneyRp(_declaredItemsFee.toStringAsFixed(0)),
            ),
          ],
          if (_voucher != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _summaryRow(
              l10n.checkoutVoucher,
              l10n.moneyRpNegative(_voucherDiscount.toStringAsFixed(0)),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.checkoutPickupDeliveryFee, style: AppTypography.body),
              Text(l10n.checkoutCalculatedAtPickup, style: AppTypography.caption),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isPerKg ? l10n.checkoutFinalPrice : l10n.checkoutTotalBeforeFee,
                  style: AppTypography.heading2),
              Text(
                _isPerKg
                    ? l10n.checkoutAfterWeighing
                    : l10n.moneyRp(
                        _perItemTotalBeforeDeliveryFee().toStringAsFixed(0)),
                style: AppTypography.heading2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isPerKg ? l10n.checkoutPerKgFooter : l10n.checkoutPerItemFooter,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
