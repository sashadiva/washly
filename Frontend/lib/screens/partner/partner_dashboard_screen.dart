import 'package:flutter/material.dart';
import '../../core/report_csv.dart';
import '../../core/report_download.dart';
import '../../l10n/app_localizations.dart';
import '../../models/partner_profile.dart';
import '../../services/partner_service.dart';
import '../../theme/app_theme.dart';
import 'partner_reviews_screen.dart';

/// The dashboard date range.
enum DashboardRange { day, month, year }

extension on DashboardRange {
  String label(AppLocalizations l10n) => switch (this) {
        DashboardRange.day => l10n.partnerDashboardRangeDay,
        DashboardRange.month => l10n.partnerDashboardRangeMonth,
        DashboardRange.year => l10n.partnerDashboardRangeYear,
      };

  /// Inclusive start for the range (local time).
  DateTime get from {
    final now = DateTime.now();
    return switch (this) {
      DashboardRange.day => DateTime(now.year, now.month, now.day),
      DashboardRange.month => DateTime(now.year, now.month, 1),
      DashboardRange.year => DateTime(now.year, 1, 1),
    };
  }
}

/// Partner dashboard: brand header + download report, a date-range selector,
/// sales metrics (in-process vs completed), and a per-product sales chart.
class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final _service = PartnerService();
  DashboardRange _range = DashboardRange.month;

  late Future<PartnerDashboard> _dashboardFuture;
  late Future<PartnerReport> _reportFuture;
  late Future<List<PartnerReview>> _reviewsFuture;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = _range.from;
    _dashboardFuture = _service.dashboard(from: from);
    _reportFuture = _service.report(from: from);
    // Reviews are all-time (not range-scoped) — a shop's reputation overall.
    _reviewsFuture = _service.reviews();
  }

  Future<void> _reload() async {
    setState(_load);
    await Future.wait([_dashboardFuture, _reportFuture, _reviewsFuture]);
  }

  void _openReviews() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PartnerReviewsScreen()));
  }

  void _setRange(DashboardRange r) {
    if (r == _range) return;
    setState(() {
      _range = r;
      _load();
    });
  }

  Future<void> _downloadReport() async {
    setState(() => _downloading = true);
    try {
      final report = await _service.report(from: _range.from);
      final csv = buildReportCsv(report);
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final where =
          await downloadTextFile('washly_sales_report_$stamp.csv', csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).partnerDashboardReportSaved(where)),
          backgroundColor: AppColors.success,
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
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
            children: [
              _headerRow(),
              const SizedBox(height: AppSpacing.lg),
              _rangeSelector(),
              const SizedBox(height: AppSpacing.xl),
              _metricsSection(),
              const SizedBox(height: AppSpacing.xxl),
              _chartSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    final l10n = AppLocalizations.of(context);
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
        Text(
          l10n.partnerDashboardTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: AppColors.primaryDark,
          ),
        ),
        const Spacer(),
        // Outlined blue report button (no fill).
        OutlinedButton.icon(
          onPressed: _downloading ? null : _downloadReport,
          icon: _downloading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined, size: 18),
          label: Text(l10n.partnerDashboardReport),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _rangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: DashboardRange.values.map((r) {
          final selected = r == _range;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setRange(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  r.label(AppLocalizations.of(context)),
                  style: AppTypography.caption.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metricsSection() {
    return FutureBuilder<PartnerDashboard>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            '${snapshot.error}'.replaceFirst('Exception: ', ''),
            style: AppTypography.body.copyWith(color: AppColors.error),
          );
        }
        final l10n = AppLocalizations.of(context);
        final d = snapshot.data!;
        return Column(
          children: [
            _metric(
                l10n.partnerDashboardRevenue,
                'Rp ${d.revenue.toStringAsFixed(0)}',
                Icons.payments_outlined,
                AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _metric(l10n.partnerDashboardInProcess,
                      '${d.inProcessOrderCount}',
                      Icons.sync_outlined, AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _metric(l10n.partnerDashboardCompleted,
                      '${d.completedOrderCount}',
                      Icons.check_circle_outline, AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _metric(l10n.partnerDashboardTotalOrders,
                      '${d.totalOrderCount}',
                      Icons.receipt_long_outlined, AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _reviewMetric()),
              ],
            ),
          ],
        );
      },
    );
  }

  /// A clickable Average-review tile that opens the full reviews list.
  Widget _reviewMetric() {
    return FutureBuilder<List<PartnerReview>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        final hasData = reviews.isNotEmpty;
        final avg = hasData
            ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length
            : 0.0;
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: _openReviews,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    const Icon(Icons.star, color: AppColors.ratingStar),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasData ? avg.toStringAsFixed(1) : '—',
                  style: AppTypography.heading1
                      .copyWith(color: AppColors.ratingStar),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasData
                      ? AppLocalizations.of(context)
                          .partnerDashboardAvgReview(reviews.length)
                      : AppLocalizations.of(context)
                          .partnerDashboardNoReviewsYet,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chartSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.partnerDashboardSalesByProduct, style: AppTypography.heading1),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<PartnerReport>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                '${snapshot.error}'.replaceFirst('Exception: ', ''),
                style: AppTypography.caption,
              );
            }
            final rows = snapshot.data?.perService ?? [];
            if (rows.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(l10n.partnerDashboardNoSales,
                    style: AppTypography.body),
              );
            }
            return _SalesBarChart(
                rows: rows, revenueLabel: l10n.partnerDashboardRevenueAxis);
          },
        ),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.heading1.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

/// A classic horizontal bar chart of per-product revenue: product labels down
/// the left (category axis), solid bars extending right, and an X axis with
/// gridline ticks and value labels at the bottom.
class _SalesBarChart extends StatelessWidget {
  final List<ReportServiceRow> rows;
  final String revenueLabel;
  const _SalesBarChart({required this.rows, required this.revenueLabel});

  static const double _labelWidth = 110;
  static const double _barHeight = 20;
  static const double _rowHeight = 40; // room for a 2-line label beside the bar
  static const double _rowGap = 10;

  @override
  Widget build(BuildContext context) {
    final maxRevenue =
        rows.map((r) => r.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    // "Nice" axis maximum (round up) so ticks are readable.
    final axisMax = _niceMax(maxRevenue);
    const tickCount = 4; // -> 0, 25%, 50%, 75%, 100%

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = constraints.maxWidth - _labelWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plot area with vertical gridlines behind the bars.
              Stack(
                children: [
                  // Gridlines.
                  Positioned.fill(
                    left: _labelWidth,
                    child: Row(
                      children: List.generate(tickCount + 1, (i) {
                        return Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 1,
                              color: AppColors.border,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Bars.
                  Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0) const SizedBox(height: _rowGap),
                        _barRow(rows[i], axisMax, plotWidth),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // X axis tick labels.
              Padding(
                padding: const EdgeInsets.only(left: _labelWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(tickCount + 1, (i) {
                    final v = axisMax * i / tickCount;
                    return Text(_short(v),
                        style: AppTypography.caption.copyWith(fontSize: 9));
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(revenueLabel,
                    style: AppTypography.caption.copyWith(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _barRow(ReportServiceRow r, double axisMax, double plotWidth) {
    final frac = axisMax <= 0 ? 0.0 : (r.revenue / axisMax).clamp(0.0, 1.0);
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                r.serviceName,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(fontSize: 10, height: 1.1),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: _barHeight,
                width: (plotWidth * frac).clamp(2.0, plotWidth),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Round the axis maximum up to a clean value so ticks read nicely.
  double _niceMax(double v) {
    if (v <= 0) return 1;
    final mag =
        1.0 * _pow10((v).floor().toString().length - 1);
    final step = mag / 2;
    return (v / step).ceil() * step;
  }

  int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// Compact rupiah label, e.g. 1.2M / 85k.
  String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}
