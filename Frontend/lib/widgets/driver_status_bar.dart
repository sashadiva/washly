import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// A compact, horizontal driver-POV status bar with four stages:
/// Accepted -> Picked up -> On the way -> Delivered. Small circles with the
/// label underneath; done stages filled with a check, the current stage shows
/// a pulsing ring, upcoming stages are muted.
class DriverStatusBar extends StatefulWidget {
  final OrderStatus status;
  const DriverStatusBar({super.key, required this.status});

  static const _stages = ['accepted', 'pickedUp', 'onTheWay', 'delivered'];

  static String _stageLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'accepted':
        return l10n.driverStatusBarAccepted;
      case 'pickedUp':
        return l10n.driverStatusBarPickedUp;
      case 'onTheWay':
        return l10n.driverStatusBarOnTheWay;
      case 'delivered':
        return l10n.driverStatusBarDelivered;
      default:
        return id;
    }
  }

  @override
  State<DriverStatusBar> createState() => _DriverStatusBarState();
}

class _DriverStatusBarState extends State<DriverStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _currentIndex {
    switch (widget.status) {
      case OrderStatus.accepted:
      case OrderStatus.driverAssigned:
        return 0;
      case OrderStatus.pickedUp:
      case OrderStatus.atLaundromat:
      case OrderStatus.weighedAwaitingConfirm:
      case OrderStatus.awaitingPayment:
      case OrderStatus.washing:
      case OrderStatus.readyForDelivery:
        return 1;
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.completed:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stages = DriverStatusBar._stages;
    final currentIndex = _currentIndex;
    final isCompleted = widget.status == OrderStatus.completed;

    return Row(
      // Top-align so a two-line label (e.g. "On the way") doesn't push its
      // node up relative to single-line stages.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStage = i ~/ 2;
          final done = leftStage < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              // Center the connector on the node (30px box -> center at 15).
              margin: const EdgeInsets.only(top: 14),
              color: done ? AppColors.primary : AppColors.border,
            ),
          );
        }

        final stageIndex = i ~/ 2;
        final isDone = stageIndex < currentIndex ||
            (isCompleted && stageIndex == currentIndex);
        final isCurrent = stageIndex == currentIndex && !isCompleted;
        final reached = isDone || isCurrent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _node(isDone: isDone, isCurrent: isCurrent),
            const SizedBox(height: 6),
            SizedBox(
              width: 56,
              child: Text(
                DriverStatusBar._stageLabel(l10n, stages[stageIndex]),
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: reached ? AppColors.primaryDark : AppColors.textMuted,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

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
          : null,
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
                scale: Tween<double>(begin: 0.8, end: 1.6).animate(
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
