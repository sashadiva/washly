import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/laundry_service_item.dart';
import '../models/laundromat_detail.dart';
import '../services/laundromat_service.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class LaundromatDetailScreen extends StatefulWidget {
  final int laundromatId;

  const LaundromatDetailScreen({super.key, required this.laundromatId});

  @override
  State<LaundromatDetailScreen> createState() => _LaundromatDetailScreenState();
}

class _LaundromatDetailScreenState extends State<LaundromatDetailScreen>
    with SingleTickerProviderStateMixin {
  final _service = LaundromatService();
  late TabController _tabController;
  late Future<LaundromatDetail> _detailFuture;

  final Map<int, CartItem> _cart = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _detailFuture = _service.getLaundromatDetail(widget.laundromatId);
    });
  }

  void _showAddItemModal(LaundryServiceItem item) {
    int quantity = _cart[item.id]?.quantity ?? (item.isKilo ? 3 : 1);
    final notesCtrl = TextEditingController(text: _cart[item.id]?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xl,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                          : Container(
                              width: 64,
                              height: 64,
                              color: AppColors.primaryLight,
                              child: const Icon(Icons.local_laundry_service, color: AppColors.primary),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: AppTypography.heading2),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Rp ${item.price.toStringAsFixed(0)} / ${item.isKilo ? 'kg' : 'item'}',
                            style: AppTypography.price.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xxl, color: AppColors.border),

                Text(
                  item.isKilo ? 'Select Weight in Kilograms (Min. 1 kg)' : 'Quantity of Items',
                  style: AppTypography.subheading,
                ),
                const SizedBox(height: AppSpacing.md),

                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            '$quantity ${item.isKilo ? 'kg' : 'pcs'}',
                            style: AppTypography.heading2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20, color: AppColors.primary),
                          onPressed: () => setSheetState(() => quantity++),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: item.isKilo
                        ? 'Washing Instructions (Optional)'
                        : 'Item Details (e.g. 2 Nike Dunks, 1 Coach bag)',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cart[item.id] = CartItem(
                          serviceId: item.id,
                          serviceName: item.name,
                          isKilo: item.isKilo,
                          unitPrice: item.price,
                          quantity: quantity,
                          notes: notesCtrl.text.trim(),
                        );
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text('Add to Basket • Rp ${(item.price * quantity).toStringAsFixed(0)}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddReviewDialog(int storeId) {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Write a Review', style: AppTypography.heading2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < selectedRating ? Icons.star : Icons.star_border,
                      color: AppColors.ratingStar,
                    ),
                    onPressed: () => setDlgState(() => selectedRating = idx + 1),
                  );
                }),
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: 'Your review'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.addReview(
                    laundromatId: storeId,
                    userId: 1,
                    rating: selectedRating,
                    comment: commentCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LaundromatDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final store = snapshot.data!;
        final int totalCartCount = _cart.values.fold(0, (sum, item) => sum + item.quantity);
        final double totalCartPrice = _cart.values.fold(0.0, (sum, item) => sum + item.totalPrice);

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: store.imageUrl != null && store.imageUrl!.isNotEmpty
                        ? Image.network(store.imageUrl!, fit: BoxFit.cover)
                        : Container(color: AppColors.primaryLight),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: AppTypography.heading1),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.ratingStar, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: AppTypography.subheading,
                            ),
                            Text(' (${store.reviewCount} reviews)', style: AppTypography.caption),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(store.address, style: AppTypography.body),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: AppTypography.subheading,
                      tabs: [
                        const Tab(text: 'Services Menu'),
                        Tab(text: 'Reviews (${store.reviews.length})'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Database Dynamic Services Menu
                store.services.isEmpty
                    ? const Center(child: Text('No services listed yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 90),
                        itemCount: store.services.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, i) {
                          final item = store.services[i];
                          final inCart = _cart[item.id];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  child: item.imageUrl != null
                                      ? Image.network(
                                          item.imageUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _servicePlaceholder(),
                                        )
                                      : _servicePlaceholder(),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: AppTypography.heading2),
                                      if (item.description != null) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          item.description!,
                                          style: AppTypography.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Rp ${item.price.toStringAsFixed(0)} / ${item.isKilo ? 'kg' : 'item'}',
                                        style: AppTypography.price,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                inCart == null
                                    ? InkWell(
                                        onTap: () => _showAddItemModal(item),
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 22),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (inCart.quantity > 1) {
                                                    inCart.quantity--;
                                                  } else {
                                                    _cart.remove(item.id);
                                                  }
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(AppSpacing.xs),
                                                child: Icon(Icons.remove, size: 18, color: AppColors.error),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                              child: Text(
                                                '${inCart.quantity}',
                                                style: AppTypography.subheading,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => setState(() => inCart.quantity++),
                                              child: const Padding(
                                                padding: EdgeInsets.all(AppSpacing.xs),
                                                child: Icon(Icons.add, size: 18, color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),

                // TAB 2: Customer Reviews
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${store.reviews.length} Customer Reviews', style: AppTypography.heading2),
                          TextButton.icon(
                            onPressed: () => _showAddReviewDialog(store.id),
                            icon: const Icon(Icons.rate_review, size: 18, color: AppColors.primary),
                            label: const Text(
                              'Add Review',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: store.reviews.isEmpty
                          ? Center(
                              child: Text(
                                'No reviews yet. Be the first to leave one!',
                                style: AppTypography.body,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: store.reviews.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: AppSpacing.xxl,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, i) {
                                final r = store.reviews[i];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primaryLight,
                                          child: Text(
                                            r.userName[0],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(r.userName, style: AppTypography.subheading),
                                        const Spacer(),
                                        Row(
                                          children: List.generate(
                                            r.rating,
                                            (_) => const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: AppColors.ratingStar,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r.comment != null && r.comment!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(r.comment!, style: AppTypography.body),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Blue Cart Bar
          bottomSheet: _cart.isNotEmpty && _tabController.index == 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            store: store,
                            cart: _cart.values.toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$totalCartCount items in basket', style: AppTypography.subheading.copyWith(color: Colors.white)),
                        Text(
                          'Rp ${totalCartPrice.toStringAsFixed(0)}  ➔',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _servicePlaceholder() => Container(
        width: 80,
        height: 80,
        color: AppColors.primaryLight,
        child: const Icon(Icons.local_laundry_service, color: AppColors.primary),
      );
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverHeaderDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) => false;
}