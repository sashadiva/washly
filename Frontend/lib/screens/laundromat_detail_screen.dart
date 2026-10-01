import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_store.dart';
import '../core/cart_store.dart';
import '../l10n/app_localizations.dart';
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

  void _showAddItemModal(LaundromatDetail store, LaundryServiceItem item) {
    final l10n = AppLocalizations.of(context);
    final cart = context.read<CartStore>();
    final existing = cart.itemFor(item.id);
    // Per-kg: the customer no longer picks a weight. Quantity is a fixed
    // placeholder (1); the real weight/price is set by the laundromat at
    // weigh-in. Per-item: the stepper below drives the quantity.
    int quantity = item.isKilo ? 1 : (existing?.quantity ?? 1);
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

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
                            l10n.detailPricePerUnit(
                                item.price.toStringAsFixed(0),
                                item.isKilo ? l10n.detailUnitKg : l10n.detailUnitItem),
                            style: AppTypography.price.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xxl, color: AppColors.border),

                if (item.isKilo)
                  // Per-kg: no weight input. The laundromat weighs the laundry
                  // and sends the price for the customer to approve before paying.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.scale_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.detailPerKgNote(item.price.toStringAsFixed(0)),
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(l10n.detailQuantityOfItems, style: AppTypography.subheading),
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
                            onPressed: quantity > 1
                                ? () => setSheetState(() => quantity--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Text(l10n.detailPieces(quantity),
                                style: AppTypography.heading2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add,
                                size: 20, color: AppColors.primary),
                            onPressed: () => setSheetState(() => quantity++),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: item.isKilo
                        ? l10n.detailWashingInstructions
                        : l10n.detailItemDetailsHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await _ensureCartScope(store);
                      if (!ok) return;
                      cart.setItem(
                        store.id,
                        store.name,
                        CartItem(
                          serviceId: item.id,
                          serviceName: item.name,
                          isKilo: item.isKilo,
                          unitPrice: item.price,
                          quantity: quantity,
                          notes: notesCtrl.text.trim(),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(item.isKilo
                        ? l10n.detailAddToBasket
                        : l10n.detailAddToBasketPrice(
                            (item.price * quantity).toStringAsFixed(0))),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// If the cart holds items from another laundromat, ask to clear it first.
  /// Returns true if it's safe to proceed adding for [store].
  Future<bool> _ensureCartScope(LaundromatDetail store) async {
    final l10n = AppLocalizations.of(context);
    final cart = context.read<CartStore>();
    if (!cart.wouldReplace(store.id)) return true;

    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.detailNewBasketTitle),
        content: Text(
          l10n.detailNewBasketBody(
            cart.laundromatName ?? l10n.detailAnotherLaundromat,
            store.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.detailClearAndAdd),
          ),
        ],
      ),
    );
    if (replace == true) {
      cart.clear();
      return true;
    }
    return false;
  }

  void _showAddReviewDialog(int storeId) {
    final l10n = AppLocalizations.of(context);
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.detailWriteReview, style: AppTypography.heading2),
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
                decoration: InputDecoration(labelText: l10n.detailYourReview),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = context.read<AuthStore>().currentUser?.id;
                final messenger = ScaffoldMessenger.of(context);
                if (userId == null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.detailSignInToReview)),
                  );
                  return;
                }
                try {
                  await _service.addReview(
                    laundromatId: storeId,
                    userId: userId,
                    rating: selectedRating,
                    comment: commentCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.detailReviewFailed('$e'))),
                  );
                }
              },
              child: Text(l10n.commonPost),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<LaundromatDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.discoveryError('${snapshot.error}'))));
        }

        final store = snapshot.data!;
        final cart = context.watch<CartStore>();
        // Only reflect this laundromat's items in the bar (the cart may hold
        // another store's items, but this screen shows only this store's).
        final bool cartForThisStore = cart.laundromatId == store.id;
        final int totalCartCount = cartForThisStore ? cart.itemCount : 0;
        final double totalCartPrice = cartForThisStore ? cart.subtotal : 0;

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
                            Text(l10n.detailReviewCountSuffix(store.reviewCount),
                                style: AppTypography.caption),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(store.areaLabel ?? l10n.detailAreaHidden,
                            style: AppTypography.body),
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
                        Tab(text: l10n.detailServicesMenu),
                        Tab(text: l10n.detailReviewsCount(store.reviews.length)),
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
                    ? Center(child: Text(l10n.detailNoServices))
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
                          final inCart = cartForThisStore
                              ? cart.itemFor(item.id)
                              : null;

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
                                        l10n.detailPricePerUnit(
                                            item.price.toStringAsFixed(0),
                                            item.isKilo
                                                ? l10n.detailUnitKg
                                                : l10n.detailUnitItem),
                                        style: AppTypography.price,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                inCart == null
                                    ? InkWell(
                                        onTap: () => _showAddItemModal(store, item),
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
                                    : item.isKilo
                                        // Per-kg: no quantity to adjust. Show an
                                        // "in basket" pill that removes on tap.
                                        ? InkWell(
                                            onTap: () => cart.decrement(item.id),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.pill),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.sm,
                                                vertical: 6,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.check,
                                                      size: 16,
                                                      color:
                                                          AppColors.primary),
                                                  const SizedBox(
                                                      width: AppSpacing.xs),
                                                  Text(l10n.detailInBasket,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.primary,
                                                      )),
                                                  const SizedBox(
                                                      width: AppSpacing.xs),
                                                  const Icon(Icons.close,
                                                      size: 14,
                                                      color:
                                                          AppColors.textMuted),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.pill),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.xs,
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () =>
                                                      cart.decrement(item.id),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(
                                                        AppSpacing.xs),
                                                    child: Icon(Icons.remove,
                                                        size: 18,
                                                        color:
                                                            AppColors.error),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.sm),
                                                  child: Text(
                                                    '${inCart.quantity}',
                                                    style:
                                                        AppTypography.subheading,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () =>
                                                      cart.increment(item.id),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(
                                                        AppSpacing.xs),
                                                    child: Icon(Icons.add,
                                                        size: 18,
                                                        color:
                                                            AppColors.primary),
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
                          Text(l10n.detailCustomerReviews(store.reviews.length),
                              style: AppTypography.heading2),
                          TextButton.icon(
                            onPressed: () => _showAddReviewDialog(store.id),
                            icon: const Icon(Icons.rate_review, size: 18, color: AppColors.primary),
                            label: Text(
                              l10n.detailAddReview,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
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
                                l10n.detailNoReviews,
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
          bottomSheet: cartForThisStore &&
                  cart.isNotEmpty &&
                  _tabController.index == 0
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
                            cart: cart.items,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.detailItemsInBasket(totalCartCount),
                            style: AppTypography.subheading.copyWith(color: Colors.white)),
                        Text(
                          // Per-kg price is only known after weighing, so don't
                          // show a committed rupiah total when the basket has one.
                          cart.hasKilo
                              ? l10n.detailWeighedAtPickupArrow
                              : l10n.detailBasketTotalArrow(
                                  totalCartPrice.toStringAsFixed(0)),
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