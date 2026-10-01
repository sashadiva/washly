import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../services/warranty_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_timeline.dart';
import 'partner_order_detail_screen.dart';

/// Partner Orders: an Open-for-orders toggle up top, then Active and Done
/// sections. Tapping an order opens its detail (accept, intake, status, etc.).
class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen> {
  final _service = PartnerService();
  final _warranty = WarrantyService();

  List<Order> _orders = const [];
  PartnerProfile? _profile;
  Set<int> _ordersNeedingWarranty = {};
  bool _loading = true;
  bool _togglingOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.orders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {}
    try {
      final p = await _service.profile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
    try {
      final claims = await _warranty.partnerClaims();
      if (mounted) {
        setState(() => _ordersNeedingWarranty = claims
            .where((c) => c.status == 'SUBMITTED')
            .map((c) => c.orderId)
            .toSet());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleOpen(bool open) async {
    setState(() => _togglingOpen = true);
    try {
      await _service.updateProfile(isOpen: open);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingOpen = false);
    }
  }

  Future<void> _openDetail(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerOrderDetailScreen(orderId: order.id),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = _orders.where((o) => o.status.isActive).toList();
    final done = _orders.where((o) => o.status.isTerminal).toList();

    if (_loading && _orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.partnerOrdersTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.partnerOrdersTitle)),
        body: Column(
          children: [
            // Open-for-orders toggle above the tabs.
            if (_profile != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: _openToggle(_profile!, l10n),
              ),
            const SizedBox(height: AppSpacing.md),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTypography.subheading,
              tabs: [
                Tab(text: l10n.partnerOrdersActiveTab(active.length)),
                Tab(text: l10n.partnerOrdersDoneTab(done.length)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _orderList(active, l10n.partnerOrdersEmptyActive, l10n),
                  _orderList(done, l10n.partnerOrdersEmptyDone, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderList(List<Order> orders, String emptyText, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _load,
      child: orders.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText, style: AppTypography.body)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
              itemCount: orders.length,
              itemBuilder: (_, i) => _orderTile(orders[i], l10n),
            ),
    );
  }

  Widget _openToggle(PartnerProfile p, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.isOpen ? AppColors.primaryLight : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: p.isOpen ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(p.isOpen ? Icons.storefront : Icons.storefront_outlined,
              color: p.isOpen ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    p.isOpen
                        ? l10n.partnerOrdersOpenForOrders
                        : l10n.partnerOrdersClosed,
                    style: AppTypography.subheading),
                Text(
                  p.isOpen
                      ? l10n.partnerOrdersOpenHint
                      : l10n.partnerOrdersClosedHint,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (_togglingOpen)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: p.isOpen,
              activeThumbColor: AppColors.primary,
              onChanged: _toggleOpen,
            ),
        ],
      ),
    );
  }

  Widget _orderTile(Order order, AppLocalizations l10n) {
    final needsWarranty = _ordersNeedingWarranty.contains(order.id);
    final total = order.finalTotal;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: needsWarranty
              ? AppColors.ratingStar.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(order),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.orderN(order.id),
                        style: AppTypography.heading2),
                  ),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${order.isKilo ? l10n.partnerOrdersPerKg : l10n.partnerOrdersPerItem} · '
                '${l10n.partnerOrdersItemCount(order.items.length)}',
                style: AppTypography.caption,
              ),
              if (needsWarranty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.gpp_maybe_outlined,
                        size: 14, color: Color(0xFFB07A00)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.partnerOrdersNeedsWarranty,
                        style: AppTypography.caption
                            .copyWith(color: const Color(0xFFB07A00))),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.status.localizedLabel(l10n),
                      style: AppTypography.caption),
                  Text(
                    total != null
                        ? 'Rp ${total.toStringAsFixed(0)}'
                        : (order.isKilo
                            ? l10n.partnerOrdersWeighedAtPickup
                            : '—'),
                    style: AppTypography.price,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
