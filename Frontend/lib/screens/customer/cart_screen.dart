import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/cart_store.dart';
import '../../models/cart_item.dart';
import '../../services/laundromat_service.dart';
import '../../theme/app_theme.dart';
import '../checkout_screen.dart';

/// The global basket. Lists the current cart items (all from one laundromat),
/// lets the customer adjust quantities or clear the basket, and proceeds to
/// checkout by loading the laundromat's full detail first.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = LaundromatService();
  bool _loadingCheckout = false;

  Future<void> _proceed() async {
    final cart = context.read<CartStore>();
    final storeId = cart.laundromatId;
    if (storeId == null || cart.isEmpty) return;

    setState(() => _loadingCheckout = true);
    try {
      final detail = await _service.getLaundromatDetail(storeId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutScreen(store: detail, cart: cart.items),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCheckout = false);
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear basket?'),
        content: const Text('This removes all items from your basket.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<CartStore>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Basket'),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear basket',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: cart.isEmpty
          ? _empty()
          : Column(
              children: [
                if (cart.laundromatName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(cart.laundromatName!,
                              style: AppTypography.subheading),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: cart.items
                        .map((item) => _CartRow(
                              item: item,
                              onAdd: () => cart.increment(item.serviceId),
                              onRemove: () => cart.decrement(item.serviceId),
                              onDelete: () => cart.removeItem(item.serviceId),
                            ))
                        .toList(),
                  ),
                ),
                _summaryBar(cart),
              ],
            ),
    );
  }

  Widget _summaryBar(CartStore cart) {
    final perKg = cart.items.any((i) => i.isKilo);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: AppTypography.body),
                Text(
                  perKg
                      ? 'From Rp ${cart.subtotal.toStringAsFixed(0)}'
                      : 'Rp ${cart.subtotal.toStringAsFixed(0)}',
                  style: AppTypography.heading2,
                ),
              ],
            ),
            if (perKg) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Final per-kg price is set after weighing.',
                  style: AppTypography.caption),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadingCheckout ? null : _proceed,
              child: _loadingCheckout
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Proceed to checkout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text('Your basket is empty.',
                style: AppTypography.subheading),
            const SizedBox(height: AppSpacing.xs),
            Text('Add services from a laundromat to get started.',
                textAlign: TextAlign.center, style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CartRow({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unit = item.isKilo ? 'kg' : 'pcs';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.serviceName, style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rp ${item.unitPrice.toStringAsFixed(0)} / $unit',
                  style: AppTypography.caption,
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${item.totalPrice.toStringAsFixed(0)}',
                  style: AppTypography.price),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(Icons.remove,
                            size: 18, color: AppColors.error),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text('${item.quantity}',
                          style: AppTypography.subheading),
                    ),
                    InkWell(
                      onTap: onAdd,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(Icons.add,
                            size: 18, color: AppColors.primary),
                      ),
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
}
