import 'package:flutter/material.dart';
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
    _Stage('Placed', Icons.receipt_long, [OrderStatus.pendingAcceptance]),
    _Stage('Accepted', Icons.check_circle_outline, [OrderStatus.accepted]),
    _Stage('Picked up', Icons.local_shipping_outlined, [
      OrderStatus.driverAssigned,
      OrderStatus.pickedUp,
      OrderStatus.weighedAwaitingConfirm,
      OrderStatus.awaitingPayment,
    ]),
    _Stage('Washing', Icons.local_laundry_service_outlined,
        [OrderStatus.washing]),
    _Stage('On the way', Icons.delivery_dining, [
      OrderStatus.readyForDelivery,
      OrderStatus.outForDelivery,
    ]),
    _Stage('Completed', Icons.verified, [OrderStatus.completed]),
  ];

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
            Text('Order cancelled',
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
                  _node(stages[i], isDone: isDone, isCurrent: isCurrent),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              isDone ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: isLast ? 0 : AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stages[i].label,
                      style: AppTypography.subheading.copyWith(
                        color: reached
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 2),
                      Text(widget.order.status.label,
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

  /// A stage node. Every circle has an outline ring. The current stage adds a
  /// gentle pulsing halo behind it.
  Widget _node(_Stage stage, {required bool isDone, required bool isCurrent}) {
    const double size = 34;
    const double box = 54;

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone || isCurrent ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isDone
              ? AppColors.primaryDark
              : (isCurrent ? AppColors.primaryLight : AppColors.border),
          width: isCurrent ? 3 : 2,
        ),
      ),
      child: Icon(
        isDone ? Icons.check : stage.icon,
        size: 18,
        color: isDone || isCurrent ? Colors.white : AppColors.textMuted,
      ),
    );

    if (!isCurrent) {
      return SizedBox(
        width: box,
        height: size,
        child: Center(child: circle),
      );
    }

    // Current stage: a pulsing halo (framework-driven, non-interactive) behind
    // the node.
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 0.0).animate(_pulse),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.8).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
                ),
                child: Container(
                  width: size,
                  height: size,
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
        status.label,
        style: AppTypography.caption.copyWith(color: fg),
      ),
    );
  }
}
