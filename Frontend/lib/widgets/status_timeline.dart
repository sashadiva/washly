import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// A vertical, discrete-stage timeline of an order's lifecycle (no map).
/// Completed stages are filled with a check, the current in-progress stage
/// gets a gentle pulsing halo + stage icon, and future stages are muted.
/// Cancelled orders render a single terminal error banner.
///
/// The pulse is driven by framework transition widgets (not a per-frame
/// AnimatedBuilder) and the halo is wrapped in IgnorePointer, to avoid the
/// Flutter web mouse-tracker assertion that a continuously-rebuilding subtree
/// can trigger during hit-testing.
class StatusTimeline extends StatefulWidget {
  final Order order;
  const StatusTimeline({super.key, required this.order});

  static const List<_Stage> _stages = [
    _Stage('placed', Icons.receipt_long, [OrderStatus.pendingAcceptance]),
    _Stage('accepted', Icons.check_circle_outline, [OrderStatus.accepted]),
    _Stage('pickup', Icons.local_shipping_outlined, [
      OrderStatus.driverAssigned,
      OrderStatus.pickedUp,
      OrderStatus.atLaundromat,
      OrderStatus.weighedAwaitingConfirm,
      OrderStatus.awaitingPayment,
    ]),
    _Stage('washing', Icons.local_laundry_service_outlined,
        [OrderStatus.washing]),
    _Stage('onTheWay', Icons.delivery_dining, [
      OrderStatus.readyForDelivery,
      OrderStatus.outForDelivery,
    ]),
    _Stage('completed', Icons.verified, [OrderStatus.completed]),
  ];

  static String _stageLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'placed':
        return l10n.timelinePlaced;
      case 'accepted':
        return l10n.timelineAccepted;
      case 'pickup':
        return l10n.timelinePickup;
      case 'washing':
        return l10n.timelineWashing;
      case 'onTheWay':
        return l10n.timelineOnTheWay;
      case 'completed':
        return l10n.timelineCompleted;
      default:
        return id;
    }
  }

  @override
  State<StatusTimeline> createState() => _StatusTimelineState();
}

class _StatusTimelineState extends State<StatusTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _currentIndex {
    final status = widget.order.status;
    final stages = StatusTimeline._stages;
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].statuses.contains(status)) return i;
    }
    if (status == OrderStatus.completed) return stages.length - 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.order.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.timelineOrderCancelled,
                style: AppTypography.subheading
                    .copyWith(color: AppColors.error)),
          ],
        ),
      );
    }

    final stages = StatusTimeline._stages;
    final currentIndex = _currentIndex;
    final isCompleted = widget.order.status == OrderStatus.completed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length, (i) {
        final isDone = i < currentIndex || (isCompleted && i == currentIndex);
        final isCurrent = i == currentIndex && !isCompleted;
        final isLast = i == stages.length - 1;
        final reached = isDone || isCurrent;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _node(isDone: isDone, isCurrent: isCurrent),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(
                  // Nudge the label to vertically centre with the small circle.
                  top: 4,
                  bottom: isLast ? 0 : AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StatusTimeline._stageLabel(l10n, stages[i].label),
                      style: AppTypography.subheading.copyWith(
                        color: reached
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 2),
                      Text(widget.order.status.localizedLabel(l10n),
                          style: AppTypography.caption
                              .copyWith(color: AppColors.primaryDark)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// A stage node matching the driver status bar's circle design, but used in
  /// the vertical timeline: done = filled with a check, current = filled with a
  /// white inner dot and a pulsing halo, upcoming = empty outline.
  Widget _node({required bool isDone, required bool isCurrent}) {
    const double dot = 18;
    const double box = 30;

    final circle = Container(
      width: dot,
      height: dot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone || isCurrent ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isDone || isCurrent ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, size: 11, color: Colors.white)
          : (isCurrent
              ? const Center(
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : null),
    );

    if (!isCurrent) {
      return SizedBox(
        width: box,
        height: box,
        child: Center(child: circle),
      );
    }

    // Current stage: pulsing halo behind the dot (framework-driven, web-safe).
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 0.0).animate(_pulse),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.7).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
                ),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          circle,
        ],
      ),
    );
  }
}

class _Stage {
  final String label;
  final IconData icon;
  final List<OrderStatus> statuses;
  const _Stage(this.label, this.icon, this.statuses);
}

/// A compact colored chip showing the order status, mapping lifecycle states to
/// existing theme tokens (success/error/primary/muted).
class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case OrderStatus.completed:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case OrderStatus.cancelled:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case OrderStatus.pendingAcceptance:
      case OrderStatus.weighedAwaitingConfirm:
      case OrderStatus.awaitingPayment:
        bg = AppColors.ratingStar.withValues(alpha: 0.15);
        fg = const Color(0xFFB07A00);
        break;
      default:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.localizedLabel(AppLocalizations.of(context)),
        style: AppTypography.caption.copyWith(color: fg),
      ),
    );
  }
}
