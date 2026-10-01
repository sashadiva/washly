import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_store.dart';
import '../../core/cart_store.dart';
import '../../l10n/app_localizations.dart';
import '../../models/laundromat.dart';
import '../../models/order.dart';
import '../../models/wallet.dart';
import '../../services/laundromat_service.dart';
import '../../services/loyalty_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';
import '../discovery_screen.dart';
import 'cart_screen.dart';
import 'laundromat_search_screen.dart';
import 'order_detail_screen.dart';
import 'vouchers_screen.dart';

/// The customer landing/home hub. Layout, top to bottom:
///   1. Search bar (taps into the full Discovery list)
///   2. Hero with greeting + loyalty balance + redeem button
///   3. Active-orders box (animated vehicle icon when an order is live)
///   4. Specialties grid (3 per row, square tiles)
///   5. Popular laundromats (top 2 by rating)
class CustomerHomeScreen extends StatefulWidget {
  /// Switch the shell to the Discovery tab.
  final VoidCallback onOpenDiscovery;

  /// Switch the shell to the Orders tab.
  final VoidCallback onOpenOrders;

  const CustomerHomeScreen({
    super.key,
    required this.onOpenDiscovery,
    required this.onOpenOrders,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _orders = OrderService();
  final _loyalty = LoyaltyService();
  final _laundromats = LaundromatService();

  late Future<List<Order>> _ordersFuture;
  late Future<Wallet> _walletFuture;
  late Future<List<Laundromat>> _nearbyFuture;

  // Tag value (sent to Discovery, kept unchanged) + icon. The visible label is
  // resolved from l10n at build time.
  static const _specialties = [
    ('shoes', Icons.ice_skating_outlined),
    ('bags', Icons.work_outline),
    ('kiloan', Icons.local_laundry_service_outlined),
    ('express', Icons.bolt_outlined),
    ('dolls', Icons.toys_outlined),
    ('dry clean', Icons.dry_cleaning_outlined),
  ];

  String _specialtyLabel(AppLocalizations l10n, String tag) {
    switch (tag) {
      case 'shoes':
        return l10n.serviceTagShoes;
      case 'bags':
        return l10n.serviceTagBags;
      case 'kiloan':
        return l10n.serviceTagKiloan;
      case 'express':
        return l10n.serviceTagExpress;
      case 'dolls':
        return l10n.serviceTagDolls;
      case 'dry clean':
        return l10n.serviceTagDryClean;
      default:
        return tag;
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ordersFuture = _orders.myOrders();
    _walletFuture = _loyalty.wallet();
    _nearbyFuture = _laundromats.fetchLaundromats(
      sortBy: 'distance',
      lat: -6.200000,
      lng: 106.780000,
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_ordersFuture, _walletFuture, _nearbyFuture]);
  }

  Future<void> _openVouchers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VouchersScreen()),
    );
    // Refresh the wallet on return in case a voucher was redeemed.
    if (mounted) {
      setState(() {
        _walletFuture = _loyalty.wallet();
      });
    }
  }

  void _openSpecialty(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscoveryScreen(initialTag: tag)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = context.watch<AuthStore>().currentUser?.name ?? '';
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              _brandHeader(),
              const SizedBox(height: AppSpacing.lg),
              _searchBar(l10n),
              const SizedBox(height: AppSpacing.xxl),
              _heroWithLoyalty(l10n, name),
              const SizedBox(height: AppSpacing.xxl),
              _activeOrderSection(l10n),
              const SizedBox(height: AppSpacing.xxl),
              Text(l10n.homeSpecialties, style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.md),
              _specialtyGrid(l10n),
              const SizedBox(height: AppSpacing.xxl),
              _nearbySection(l10n),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // 0. Brand header (logo + wordmark, top-left) --------------------------------

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
        const Spacer(),
        // Cart button, aligned right with the logo, with a live item badge.
        _cartButton(),
      ],
    );
  }

  Widget _cartButton() {
    final count = context.watch<CartStore>().itemCount;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                color: AppColors.primaryDark, size: 22),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 1. Search bar --------------------------------------------------------------

  Widget _searchBar(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LaundromatSearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.homeSearchHint, style: AppTypography.body),
          ],
        ),
      ),
    );
  }

  // 2. Hero + loyalty ----------------------------------------------------------

  Widget _heroWithLoyalty(AppLocalizations l10n, String name) {
    return FutureBuilder<Wallet>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final wallet = snapshot.data;
        final balance = wallet?.balance ?? 0;
        final vouchers = wallet?.availableVouchers ?? const [];
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeWelcomeBack,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      name.isEmpty ? l10n.homeGreetingFallback : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Loyalty row: points + redeem, merged into the hero.
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  loading
                                      ? l10n.homeLoyaltyWallet
                                      : l10n.homePoints(balance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (loading)
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            vouchers.isEmpty
                                ? l10n.homeRedeemPrompt
                                : l10n.homeVouchersReady(vouchers.length),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // White filled button that opens the Vouchers page
                          // (redemption happens there).
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openVouchers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                minimumSize: const Size(0, 44),
                              ),
                              child: Text(l10n.commonRedeem),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. Active orders -----------------------------------------------------------

  Widget _activeOrderSection(AppLocalizations l10n) {
    return FutureBuilder<List<Order>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final orders = snapshot.data ?? [];
        final active = orders.where((o) => o.status.isActive).toList();
        final hasActive = active.isNotEmpty;

        return Container(
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
                  if (hasActive) ...[
                    const _AnimatedDeliveryIcon(),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(l10n.homeActiveOrders,
                        style: AppTypography.subheading),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (loading)
                const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!hasActive)
                Text(l10n.homeNoActiveOrders,
                    style: AppTypography.body)
              else
                _activeOrderTile(l10n, active.first),
            ],
          ),
        );
      },
    );
  }

  Widget _activeOrderTile(AppLocalizations l10n, Order order) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _openOrder(order.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.laundromat?.name ?? l10n.homeYourOrder,
                      style: AppTypography.heading2),
                ),
                StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.homeTapToTrack(order.id),
                style: AppTypography.caption),
            if (order.needsWeightApproval) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.homeActionConfirmWeighedPrice,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.primaryDark)),
            ],
          ],
        ),
      ),
    );
  }

  // 4. Specialties grid --------------------------------------------------------

  Widget _specialtyGrid(AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 3.2,
      children: _specialties.map((s) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _openSpecialty(s.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(s.$2, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _specialtyLabel(l10n, s.$1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.subheading,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Nearby laundromats ------------------------------------------------------

  Widget _nearbySection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.homeNearbyLaundromats,
                  style: AppTypography.heading1),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
                );
              },
              child: Text(l10n.commonSeeAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        FutureBuilder<List<Laundromat>>(
          future: _nearbyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                '${snapshot.error}'.replaceFirst('Exception: ', ''),
                style: AppTypography.caption,
              );
            }
            final nearby = (snapshot.data ?? []).take(2).toList();
            if (nearby.isEmpty) {
              return Text(l10n.homeNoLaundromatsYet,
                  style: AppTypography.body);
            }
            // Reuse Discovery's full card, but drop its default horizontal
            // margin so it aligns with the rest of the home content (the
            // ListView already applies lg padding).
            return Column(
              children: nearby
                  .map((store) => LaundromatListingCard(
                        store: store,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openOrder(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: id)),
    );
    _refresh();
  }
}

/// A small looping vehicle icon that nudges left-to-right to signal an
/// in-progress delivery.
class _AnimatedDeliveryIcon extends StatefulWidget {
  const _AnimatedDeliveryIcon();

  @override
  State<_AnimatedDeliveryIcon> createState() => _AnimatedDeliveryIconState();
}

class _AnimatedDeliveryIconState extends State<_AnimatedDeliveryIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _offset = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedBuilder(
        animation: _offset,
        builder: (_, child) => Transform.translate(
          offset: Offset(_offset.value, 0),
          child: child,
        ),
        child: const Icon(Icons.local_shipping_outlined,
            size: 20, color: AppColors.primary),
      ),
    );
  }
}

