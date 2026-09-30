/**
 * Order lifecycle state machine (Requirements 5, 6, 7, 10, 13, 14).
 *
 * Centralizes the allowed transitions and the role permitted to trigger each,
 * so routes never mutate `Order.status` directly. Illegal transitions are
 * surfaced as an error the routes translate into HTTP 409.
 *
 * Lifecycle (per design):
 *   PENDING_ACCEPTANCE
 *     -> ACCEPTED            (partner accepts; per-item requires payment SETTLED)
 *     -> CANCELLED           (partner rejects / customer cancels)
 *   ACCEPTED
 *     -> DRIVER_ASSIGNED     (driver accepts pickup offer)
 *   DRIVER_ASSIGNED
 *     -> PICKED_UP           (driver marks picked up)
 *   PICKED_UP
 *     -> WEIGHED_AWAITING_CONFIRM   (per-kg: partner weighs)
 *     -> WASHING                    (per-item: already paid at checkout)
 *   WEIGHED_AWAITING_CONFIRM
 *     -> AWAITING_PAYMENT    (customer approves weighed price)
 *   AWAITING_PAYMENT
 *     -> WASHING             (payment SETTLED)
 *   WASHING
 *     -> READY_FOR_DELIVERY  (partner marks ready)
 *   READY_FOR_DELIVERY
 *     -> OUT_FOR_DELIVERY    (driver accepts delivery offer + is delivering)
 *   OUT_FOR_DELIVERY
 *     -> COMPLETED           (driver marks delivered)
 */

import type { OrderStatus, Role } from '@prisma/client';

export type OrderAction =
  | 'accept'
  | 'reject'
  | 'assignDriver'
  | 'markPickedUp'
  | 'enterWeight'
  | 'approveWeight'
  | 'confirmPayment'
  | 'markReady'
  | 'startDelivery'
  | 'markDelivered'
  | 'cancel';

interface TransitionRule {
  /** States the order may be in for this action to be legal. */
  from: OrderStatus[];
  /** Resulting state after the action. */
  to: OrderStatus;
  /**
   * Roles allowed to trigger this action. `SYSTEM` marks transitions driven by
   * server-side effects (e.g. a verified payment webhook) rather than a user.
   */
  roles: Array<Role | 'SYSTEM'>;
}

const TRANSITIONS: Record<OrderAction, TransitionRule> = {
  accept: {
    from: ['PENDING_ACCEPTANCE'],
    to: 'ACCEPTED',
    roles: ['PARTNER'],
  },
  reject: {
    from: ['PENDING_ACCEPTANCE'],
    to: 'CANCELLED',
    roles: ['PARTNER'],
  },
  cancel: {
    from: ['PENDING_ACCEPTANCE', 'ACCEPTED'],
    to: 'CANCELLED',
    roles: ['CUSTOMER', 'PARTNER'],
  },
  assignDriver: {
    from: ['ACCEPTED'],
    to: 'DRIVER_ASSIGNED',
    roles: ['DRIVER', 'SYSTEM'],
  },
  markPickedUp: {
    from: ['DRIVER_ASSIGNED'],
    to: 'PICKED_UP',
    roles: ['DRIVER'],
  },
  enterWeight: {
    from: ['PICKED_UP'],
    to: 'WEIGHED_AWAITING_CONFIRM',
    roles: ['PARTNER'],
  },
  approveWeight: {
    from: ['WEIGHED_AWAITING_CONFIRM'],
    to: 'AWAITING_PAYMENT',
    roles: ['CUSTOMER'],
  },
  confirmPayment: {
    // Per-kg: AWAITING_PAYMENT -> WASHING. Per-item: PICKED_UP -> WASHING
    // (already paid at checkout, so payment confirmation advances after pickup).
    from: ['AWAITING_PAYMENT', 'PICKED_UP'],
    to: 'WASHING',
    roles: ['SYSTEM'],
  },
  markReady: {
    from: ['WASHING'],
    to: 'READY_FOR_DELIVERY',
    roles: ['PARTNER'],
  },
  startDelivery: {
    from: ['READY_FOR_DELIVERY'],
    to: 'OUT_FOR_DELIVERY',
    roles: ['DRIVER', 'SYSTEM'],
  },
  markDelivered: {
    from: ['OUT_FOR_DELIVERY'],
    to: 'COMPLETED',
    roles: ['DRIVER'],
  },
};

/** Raised when a transition is not permitted. Routes map this to HTTP 409. */
export class IllegalTransitionError extends Error {
  readonly currentStatus: OrderStatus;
  readonly action: OrderAction;

  constructor(action: OrderAction, currentStatus: OrderStatus, message: string) {
    super(message);
    this.name = 'IllegalTransitionError';
    this.action = action;
    this.currentStatus = currentStatus;
  }
}

/**
 * Returns true if `action` is legal from `currentStatus` for `role`,
 * without throwing. Useful for guards like canPartnerAccept.
 */
export function canTransition(
  action: OrderAction,
  currentStatus: OrderStatus,
  role: Role | 'SYSTEM'
): boolean {
  const rule = TRANSITIONS[action];
  if (!rule) return false;
  return rule.from.includes(currentStatus) && rule.roles.includes(role);
}

/**
 * Resolves the next status for a legal transition, or throws
 * IllegalTransitionError. The role must be permitted for the action AND the
 * order must be in an allowed source state.
 */
export function nextStatus(
  action: OrderAction,
  currentStatus: OrderStatus,
  role: Role | 'SYSTEM'
): OrderStatus {
  const rule = TRANSITIONS[action];

  if (!rule) {
    throw new IllegalTransitionError(action, currentStatus, `Unknown action "${action}".`);
  }

  if (!rule.roles.includes(role)) {
    throw new IllegalTransitionError(
      action,
      currentStatus,
      `Role ${role} may not perform "${action}".`
    );
  }

  if (!rule.from.includes(currentStatus)) {
    throw new IllegalTransitionError(
      action,
      currentStatus,
      `Cannot ${action} an order in state ${currentStatus}.`
    );
  }

  return rule.to;
}
