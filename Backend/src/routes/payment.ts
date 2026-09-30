import { Router, Request, Response } from 'express';
import { PaymentStatus, PricingUnit, OrderStatus } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';
import {
  createSnapTransaction,
  verifyNotificationSignature,
  mapTransactionStatus,
  type MidtransNotification,
} from '../services/midtransService.js';
import { nextStatus, IllegalTransitionError } from '../services/orderStateMachine.js';

const router = Router();

/**
 * The amount payable for an order at the current moment.
 * Per-item: finalTotal (subtotal + fee - voucher), known at creation.
 * Per-kg: finalTotal, known only after weigh-in (AWAITING_PAYMENT).
 */
function payableAmount(order: {
  finalTotal: number | null;
  itemsSubtotal: number | null;
  deliveryFee: number;
  voucherDiscount: number;
}): number | null {
  if (order.finalTotal != null) return Math.round(order.finalTotal);
  return null;
}

// ---------------------------------------------------------------------------
// POST /api/payments/:orderId/create  (customer-only)
// Creates a Midtrans Snap transaction and records a PENDING Payment.
// ---------------------------------------------------------------------------
router.post(
  '/:orderId/create',
  authGuard,
  roleGuard('CUSTOMER'),
  async (req: Request<{ orderId: string }>, res: Response) => {
    try {
      const orderId = parseInt(req.params.orderId, 10);
      if (isNaN(orderId)) {
        return res.status(400).json({ error: 'Invalid order ID.' });
      }

      const order = await prisma.order.findUnique({
        where: { id: orderId },
        include: { customer: true, payments: true },
      });
      if (!order || order.customerId !== req.user!.id) {
        return res.status(404).json({ error: 'Order not found.' });
      }

      // The order must be at a chargeable point:
      //  - per-item: pay up front while PENDING_ACCEPTANCE
      //  - per-kg:   pay after weigh approval (AWAITING_PAYMENT)
      const chargeable =
        (order.pricingModel === PricingUnit.PER_ITEM &&
          order.status === OrderStatus.PENDING_ACCEPTANCE) ||
        order.status === OrderStatus.AWAITING_PAYMENT;
      if (!chargeable) {
        return res
          .status(409)
          .json({ error: `Order is not payable in state ${order.status}.` });
      }

      const amount = payableAmount(order);
      if (amount == null || amount <= 0) {
        return res
          .status(409)
          .json({ error: 'Order total is not finalized yet.' });
      }

      // Reuse an existing PENDING payment if one is already open (idempotent
      // create), otherwise mint a new unique midtransOrderId.
      const existingPending = order.payments.find(
        (p) => p.status === PaymentStatus.PENDING && p.snapToken
      );
      if (existingPending?.snapToken) {
        return res.json({
          snapToken: existingPending.snapToken,
          midtransOrderId: existingPending.midtransOrderId,
          amount: existingPending.amount,
        });
      }

      // Unique reference per attempt (Midtrans requires order_id uniqueness).
      const midtransOrderId = `WASHLY-${order.id}-${Date.now()}`;

      const snap = await createSnapTransaction({
        orderId: midtransOrderId,
        grossAmount: amount,
        customer: {
          first_name: order.customer.name,
          email: order.customer.email,
          phone: order.customer.phone ?? undefined,
        },
      });

      await prisma.payment.create({
        data: {
          orderId: order.id,
          amount,
          status: PaymentStatus.PENDING,
          midtransOrderId,
          snapToken: snap.token,
        },
      });

      return res.json({
        snapToken: snap.token,
        redirectUrl: snap.redirectUrl,
        midtransOrderId,
        amount,
      });
    } catch (error: unknown) {
      console.error('Error creating payment:', error);
      const msg = error instanceof Error ? error.message : 'Failed to create payment.';
      return res.status(502).json({ error: msg });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/payments/webhook  (public, signature-verified — SOURCE OF TRUTH)
// Midtrans posts here. We only mutate state on a valid signature. Idempotent.
// Always 200 on a processed notification (even non-settlement) to avoid retry
// storms; 403 on invalid signature.
// ---------------------------------------------------------------------------
router.post('/webhook', async (req: Request, res: Response) => {
  try {
    const n = (req.body ?? {}) as MidtransNotification;

    if (!verifyNotificationSignature(n)) {
      // Do not reveal details; log and reject.
      console.warn('Rejected Midtrans webhook with invalid signature', {
        order_id: n.order_id,
      });
      return res.status(403).json({ error: 'Invalid signature.' });
    }

    const midtransOrderId = String(n.order_id);
    const payment = await prisma.payment.findUnique({
      where: { midtransOrderId },
      include: { order: true },
    });
    if (!payment) {
      // Unknown reference — acknowledge so Midtrans stops retrying.
      return res.status(200).json({ received: true });
    }

    const outcome = mapTransactionStatus(n);
    const newStatus = PaymentStatus[outcome as keyof typeof PaymentStatus];

    // Idempotency: if this payment is already SETTLED, acknowledge and stop.
    if (payment.status === PaymentStatus.SETTLED) {
      return res.status(200).json({ received: true, idempotent: true });
    }

    await prisma.$transaction(async (tx) => {
      await tx.payment.update({
        where: { id: payment.id },
        data: {
          status: newStatus,
          method: (n.payment_type as string) ?? payment.method,
          rawNotification: n as object,
        },
      });

      // Only a settlement advances the order along the paid path.
      if (outcome === 'SETTLED') {
        const order = payment.order;
        // confirmPayment is a SYSTEM transition: PICKED_UP or AWAITING_PAYMENT -> WASHING.
        try {
          const target = nextStatus('confirmPayment', order.status, 'SYSTEM');
          await tx.order.update({
            where: { id: order.id },
            data: { status: target },
          });
        } catch (e) {
          // If the order isn't in a state that a payment advances (e.g. per-item
          // still PENDING_ACCEPTANCE awaiting partner), leave status as-is; the
          // SETTLED payment alone unblocks partner acceptance.
          if (!(e instanceof IllegalTransitionError)) throw e;
        }
      }
    });

    return res.status(200).json({ received: true });
  } catch (error: unknown) {
    console.error('Error processing webhook:', error);
    // Still 200 to avoid retry storms; we logged the failure.
    return res.status(200).json({ received: true });
  }
});

export default router;
