import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/auth_store.dart';
import 'package:provider/provider.dart';
import '../core/cart_store.dart';
import '../core/payment_launcher.dart';
import '../models/cart_item.dart';
import '../models/laundromat_detail.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

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
  bool _isSubmitting = false;

  // Per-kg orders have no known total up front; the price is finalized after
  // the partner weighs the laundry.
  bool get _isPerKg => widget.cart.any((i) => i.isKilo);

  double get subtotal =>
      widget.cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _addDeclaredItem() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 70,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    if (!mounted) return;
    final labelCtrl = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Label this item', style: AppTypography.heading2),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'e.g. White Nike Air Force 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, labelCtrl.text.trim()),
            child: const Text('Add'),
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
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your pickup address.')),
      );
      return;
    }

    final auth = context.read<AuthStore>();
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to place an order.')),
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
    try {
      final result = await _paymentLauncher.launch(order.id);
      if (!mounted) return;
      switch (result) {
        case PaymentResult.success:
          _showResultDialog(
            title: 'Payment received',
            message:
                'Thanks! Your payment is confirmed. Track this order in the '
                'Orders tab.',
          );
          break;
        case PaymentResult.pending:
          _showResultDialog(
            title: 'Payment pending',
            message:
                'Your payment is being processed. This order updates '
                'automatically once it is confirmed.',
          );
          break;
        case PaymentResult.closed:
          _showResultDialog(
            title: 'Payment not completed',
            message:
                'You closed the payment window. Your order is saved — you can '
                'pay from the Orders tab anytime.',
          );
          break;
        case PaymentResult.error:
          _showResultDialog(
            title: 'Payment failed',
            message:
                'The payment did not go through. Your order is saved — try '
                'again from the Orders tab.',
          );
          break;
        case PaymentResult.launched:
          _showResultDialog(
            title: 'Complete your payment',
            message:
                'We opened the payment page. This order updates automatically '
                'once payment is confirmed.',
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Order placed',
        message:
            'Your order was created, but we could not open payment: '
            '${'$e'.replaceFirst('Exception: ', '')}. '
            'You can pay from the Orders tab.',
      );
    }
  }

  void _showPerKgPlaced(Order order) {
    _showResultDialog(
      title: 'Order Placed',
      message:
          'Your order is waiting for the laundromat to accept it. The final '
          'price is set after your laundry is weighed — you will pay then.',
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
            child: const Text('Done'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Order')),
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

            Text('Delivery & Pickup Details', style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Pickup & Return Address',
                prefixIcon: Icon(Icons.location_on, color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes for driver / laundromat (optional)',
                hintText: 'e.g. Leave with security, house with black gate',
                prefixIcon: Icon(Icons.notes, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
            Text('Order Summary', style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.md),
            _orderSummaryCard(),

            const SizedBox(height: AppSpacing.lg),
            _declaredItemsCard(),

            const SizedBox(height: AppSpacing.lg),
            _voucherPlaceholderCard(),

            const SizedBox(height: AppSpacing.lg),
            _priceCard(),
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
              : const Text(
                  'Place Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _orderSummaryCard() {
    return _card(
      child: Column(
        children: widget.cart.map((item) {
          final unit = item.isKilo ? 'kg' : 'pcs';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.quantity}$unit x ',
                    style: AppTypography.subheading),
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
                      ? 'Rp ${item.unitPrice.toStringAsFixed(0)}/kg'
                      : 'Rp ${item.totalPrice.toStringAsFixed(0)}',
                  style: AppTypography.body,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _declaredItemsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Declared items (optional)',
                    style: AppTypography.subheading),
              ),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _addDeclaredItem,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          Text(
            'Photograph valuable items now to enable a warranty claim later.',
            style: AppTypography.caption,
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

  Widget _voucherPlaceholderCard() {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined,
              color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Apply a voucher', style: AppTypography.subheading),
          ),
          Text('Coming soon', style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _priceCard() {
    return _card(
      child: Column(
        children: [
          _summaryRow(
            _isPerKg ? 'Estimated wash (per kg)' : 'Wash Subtotal',
            _isPerKg
                ? 'Weighed at pickup'
                : 'Rp ${subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pickup & Delivery Fee', style: AppTypography.body),
              Text('Calculated at pickup', style: AppTypography.caption),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isPerKg ? 'Final price' : 'Total (before fee)',
                  style: AppTypography.heading2),
              Text(
                _isPerKg
                    ? 'After weighing'
                    : 'Rp ${subtotal.toStringAsFixed(0)}',
                style: AppTypography.heading2.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isPerKg
                ? 'Your laundry is priced by weight. You approve the final price after it is weighed, then pay.'
                : 'The delivery fee is calculated from the pickup distance when you place the order.',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
