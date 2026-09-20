import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/laundromat_detail.dart';
import '../services/laundromat_service.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final LaundromatDetail store;
  final List<CartItem> cart;

  const CheckoutScreen({super.key, required this.store, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _service = LaundromatService();
  final _addressCtrl = TextEditingController(text: 'Jl. Rawa Belong No. 15, Palmerah');
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  double get subtotal => widget.cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => 10000.0;
  double get grandTotal => subtotal + deliveryFee;

  void _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your delivery address.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final itemsSummary = widget.cart.map((item) {
      final unit = item.isKilo ? 'kg' : 'pcs';
      final noteText = item.notes != null && item.notes!.isNotEmpty ? ' (${item.notes})' : '';
      return '${item.serviceName} x ${item.quantity}$unit$noteText';
    }).join(', ');

    final double totalKg = widget.cart
        .where((i) => i.isKilo)
        .fold(0.0, (sum, i) => sum + i.quantity);

    try {
      await _service.createOrder(
        laundromatId: widget.store.id,
        customerId: 1,
        pickupAddress: _addressCtrl.text.trim(),
        serviceType: widget.cart.first.serviceName,
        notes: 'Items: $itemsSummary. Driver note: ${_notesCtrl.text.trim()}',
        estimatedKg: totalKg > 0 ? totalKg : null,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Order Placed Successfully!', style: AppTypography.heading2),
          content: Text(
            'Driver will be dispatched to pick up your laundry at:\n\n${_addressCtrl.text.trim()}',
            style: AppTypography.body,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Discovery'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Order'),
      ),
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

            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: widget.cart.map((item) {
                    final unit = item.isKilo ? 'kg' : 'pcs';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity}$unit x ', style: AppTypography.subheading),
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
                          Text('Rp ${item.totalPrice.toStringAsFixed(0)}', style: AppTypography.body),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _priceRow('Wash Subtotal', subtotal),
                    const SizedBox(height: AppSpacing.sm),
                    _priceRow('Pickup & Delivery Fee', deliveryFee),
                    const Divider(height: AppSpacing.xl, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Payment', style: AppTypography.heading2),
                        Text(
                          'Rp ${grandTotal.toStringAsFixed(0)}',
                          style: AppTypography.heading2.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Place Order • Rp ${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text('Rp ${amount.toStringAsFixed(0)}', style: AppTypography.subheading),
      ],
    );
  }
}