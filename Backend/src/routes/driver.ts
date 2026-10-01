import { Router, Request, Response } from 'express';
import {
  Prisma,
  OfferStatus,
  DriverAvailability,
  OrderStatus,
} from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { nextStatus, IllegalTransitionError } from '../services/orderStateMachine.js';
import { reofferToNextDriver } from '../services/assignmentService.js';
import { awardPointsForOrder } from '../services/pointsService.js';

const router = Router();

// Every route here requires an authenticated DRIVER.
router.use(authGuard, roleGuard('DRIVER'));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function toFiniteNumber(v: unknown): number | null {
  const n = typeof v === 'number' ? v : parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

/** The DriverProfile for the authenticated user, or null. */
async function getOwnProfile(userId: number) {
  return prisma.driverProfile.findUnique({ where: { userId } });
}

const ORDER_INCLUDE = {
  items: true,
  // Driver-facing: coords are OK here (drivers need the map). The customer
  // route deliberately omits laundromat coords.
  laundromat: {
    select: {
      id: true,
      name: true,
      areaLabel: true,
      imageUrl: true,
      latitude: true,
      longitude: true,
    },
  },
} satisfies Prisma.OrderInclude;

// ---------------------------------------------------------------------------
// GET /api/driver/offers — orders currently OFFERED to this driver
// ---------------------------------------------------------------------------
router.get('/offers', async (req: Request, res: Response) => {
  try {
    const profile = await getOwnProfile(req.user!.id);
    if (!profile) return res.status(404).json({ error: 'No driver profile found.' });

    const offers = await prisma.deliveryOffer.findMany({
      where: { driverId: profile.id, status: OfferStatus.OFFERED },
      orderBy: { createdAt: 'desc' },
      include: { order: { include: ORDER_INCLUDE } },
    });
    return res.json(offers);
  } catch (error: unknown) {
    console.error('Error loading offers:', error);
    return res.status(500).json({ error: 'Failed to load offers.' });
  }
});

/** Load an OFFERED offer owned by this driver, or send 404 and return null. */
async function loadOwnOffer(req: Request<{ id: string }>, res: Response) {
  const offerId = parseInt(req.params.id, 10);
  if (isNaN(offerId)) {
    res.status(400).json({ error: 'Invalid offer ID.' });
    return null;
  }
  const profile = await getOwnProfile(req.user!.id);
  if (!profile) {
    res.status(404).json({ error: 'No driver profile found.' });
    return null;
  }
  const offer = await prisma.deliveryOffer.findUnique({
    where: { id: offerId },
    include: { order: true },
  });
  if (!offer || offer.driverId !== profile.id) {
    res.status(404).json({ error: 'Offer not found.' });
    return null;
  }
  return { offer, profile };
}

// ---------------------------------------------------------------------------
// POST /api/driver/offers/:id/accept
// PICKUP offer  -> order ACCEPTED -> DRIVER_ASSIGNED
// DELIVERY offer -> order READY_FOR_DELIVERY -> OUT_FOR_DELIVERY
// Assigns the driver, sets them BUSY, and expires sibling offers.
// ---------------------------------------------------------------------------
router.post('/offers/:id/accept', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnOffer(req, res);
    if (!loaded) return;
    const { offer, profile } = loaded;

    if (offer.status !== OfferStatus.OFFERED) {
      return res.status(409).json({ error: 'This offer is no longer open.' });
    }

    const action = offer.phase === 'PICKUP' ? 'assignDriver' : 'startDelivery';
    let target: OrderStatus;
    try {
      target = nextStatus(action, offer.order.status, 'DRIVER');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    const updated = await prisma.$transaction(async (tx) => {
      // Accept this offer.
      await tx.deliveryOffer.update({
        where: { id: offer.id },
        data: { status: OfferStatus.ACCEPTED, respondedAt: new Date() },
      });
      // Expire sibling OFFERED offers for the same order+phase.
      await tx.deliveryOffer.updateMany({
        where: {
          orderId: offer.orderId,
          phase: offer.phase,
          status: OfferStatus.OFFERED,
          id: { not: offer.id },
        },
        data: { status: OfferStatus.EXPIRED, respondedAt: new Date() },
      });
      // Assign the driver to the order and busy them.
      const order = await tx.order.update({
        where: { id: offer.orderId },
        data: { status: target, driverId: profile.id },
        include: ORDER_INCLUDE,
      });
      await tx.driverProfile.update({
        where: { id: profile.id },
        data: { availability: DriverAvailability.BUSY },
      });
      return order;
    });

    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error accepting offer:', error);
    return res.status(500).json({ error: 'Failed to accept offer.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/driver/offers/:id/reject — decline; re-offer to next nearest.
// ---------------------------------------------------------------------------
router.post('/offers/:id/reject', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnOffer(req, res);
    if (!loaded) return;
    const { offer } = loaded;

    if (offer.status !== OfferStatus.OFFERED) {
      return res.status(409).json({ error: 'This offer is no longer open.' });
    }

    await prisma.deliveryOffer.update({
      where: { id: offer.id },
      data: { status: OfferStatus.REJECTED, respondedAt: new Date() },
    });

    // Re-offer to the next nearest available driver (may be nobody).
    const phase = offer.phase === 'PICKUP' ? 'PICKUP' : 'DELIVERY';
    await reofferToNextDriver(offer.orderId, phase);

    return res.json({ message: 'Offer rejected.' });
  } catch (error: unknown) {
    console.error('Error rejecting offer:', error);
    return res.status(500).json({ error: 'Failed to reject offer.' });
  }
});

/** Load an order this driver is assigned to, or send 404 and return null. */
async function loadAssignedOrder(req: Request<{ id: string }>, res: Response) {
  const orderId = parseInt(req.params.id, 10);
  if (isNaN(orderId)) {
    res.status(400).json({ error: 'Invalid order ID.' });
    return null;
  }
  const profile = await getOwnProfile(req.user!.id);
  if (!profile) {
    res.status(404).json({ error: 'No driver profile found.' });
    return null;
  }
  const order = await prisma.order.findUnique({ where: { id: orderId } });
  if (!order || order.driverId !== profile.id) {
    res.status(404).json({ error: 'Order not found.' });
    return null;
  }
  return { order, profile };
}

// ---------------------------------------------------------------------------
// POST /api/driver/orders/:id/picked-up  (DRIVER_ASSIGNED -> PICKED_UP)
// The driver collected the laundry from the customer. The laundry still has to
// be dropped at the laundromat (see /arrived) before weighing/washing.
// ---------------------------------------------------------------------------
router.post('/orders/:id/picked-up', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadAssignedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    let target: OrderStatus;
    try {
      target = nextStatus('markPickedUp', order.status, 'DRIVER');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: target },
      include: ORDER_INCLUDE,
    });
    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error marking picked up:', error);
    return res.status(500).json({ error: 'Failed to update order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/driver/orders/:id/arrived  (PICKED_UP -> AT_LAUNDROMAT)
// The driver dropped the laundry at the laundromat. For per-item orders (paid
// up front), arrival advances straight to WASHING once payment is settled.
// Per-kg orders stay AT_LAUNDROMAT so the partner can weigh them.
// ---------------------------------------------------------------------------
router.post('/orders/:id/arrived', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadAssignedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    let target: OrderStatus;
    try {
      target = nextStatus('arriveAtLaundromat', order.status, 'DRIVER');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    // Arrival always lands at AT_LAUNDROMAT. The partner then performs the
    // "receive" step (confirm declared-item intake + weigh for per-kg), which
    // is what advances the order onward — including per-item -> WASHING. This
    // guarantees the partner confirms the items for every order type.
    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: target },
      include: ORDER_INCLUDE,
    });
    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error marking arrived at laundromat:', error);
    return res.status(500).json({ error: 'Failed to update order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/driver/orders/:id/delivered  (OUT_FOR_DELIVERY -> COMPLETED)
// Completion effects: free the driver (AVAILABLE) and award loyalty points.
// ---------------------------------------------------------------------------
router.post('/orders/:id/delivered', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadAssignedOrder(req, res);
    if (!loaded) return;
    const { order, profile } = loaded;

    let target: OrderStatus;
    try {
      target = nextStatus('markDelivered', order.status, 'DRIVER');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    const updated = await prisma.$transaction(async (tx) => {
      const o = await tx.order.update({
        where: { id: order.id },
        data: { status: target },
        include: ORDER_INCLUDE,
      });
      // Free the driver so they can take new offers.
      await tx.driverProfile.update({
        where: { id: profile.id },
        data: { availability: DriverAvailability.AVAILABLE },
      });
      // Loyalty: award points for the now-completed, settled order (idempotent).
      await awardPointsForOrder(order.id, tx);
      return o;
    });

    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error marking delivered:', error);
    return res.status(500).json({ error: 'Failed to update order.' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/driver/availability — set AVAILABLE / OFFLINE (+ optional location)
// Labeled "Active / Not Active" in the UI to avoid implying internet status.
// ---------------------------------------------------------------------------
router.put('/availability', async (req: Request, res: Response) => {
  try {
    const profile = await getOwnProfile(req.user!.id);
    if (!profile) return res.status(404).json({ error: 'No driver profile found.' });

    const { active, latitude, longitude } = req.body ?? {};
    if (typeof active !== 'boolean') {
      return res.status(400).json({ error: 'active (boolean) is required.' });
    }

    // Don't flip a BUSY driver to AVAILABLE via this toggle; they must finish
    // the current job. Toggling off while BUSY is also disallowed.
    if (profile.availability === DriverAvailability.BUSY) {
      return res
        .status(409)
        .json({ error: 'You are on an active delivery. Finish it before changing availability.' });
    }

    const data: Prisma.DriverProfileUpdateInput = {
      availability: active ? DriverAvailability.AVAILABLE : DriverAvailability.OFFLINE,
    };
    const lat = toFiniteNumber(latitude);
    const lng = toFiniteNumber(longitude);
    if (lat !== null) data.latitude = lat;
    if (lng !== null) data.longitude = lng;

    const updated = await prisma.driverProfile.update({
      where: { id: profile.id },
      data,
    });
    return res.json({
      id: updated.id,
      availability: updated.availability,
      latitude: updated.latitude,
      longitude: updated.longitude,
    });
  } catch (error: unknown) {
    console.error('Error updating availability:', error);
    return res.status(500).json({ error: 'Failed to update availability.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/driver/history — the driver's completed deliveries
// ---------------------------------------------------------------------------
router.get('/history', async (req: Request, res: Response) => {
  try {
    const profile = await getOwnProfile(req.user!.id);
    if (!profile) return res.status(404).json({ error: 'No driver profile found.' });

    const orders = await prisma.order.findMany({
      where: { driverId: profile.id, status: OrderStatus.COMPLETED },
      include: ORDER_INCLUDE,
      orderBy: { updatedAt: 'desc' },
    });
    return res.json(orders);
  } catch (error: unknown) {
    console.error('Error loading history:', error);
    return res.status(500).json({ error: 'Failed to load history.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/driver/active — the driver's current in-progress assignment (if any)
// ---------------------------------------------------------------------------
router.get('/active', async (req: Request, res: Response) => {
  try {
    const profile = await getOwnProfile(req.user!.id);
    if (!profile) return res.status(404).json({ error: 'No driver profile found.' });

    const order = await prisma.order.findFirst({
      where: {
        driverId: profile.id,
        status: {
          in: [
            OrderStatus.DRIVER_ASSIGNED,
            OrderStatus.PICKED_UP,
            OrderStatus.AT_LAUNDROMAT,
            OrderStatus.WEIGHED_AWAITING_CONFIRM,
            OrderStatus.AWAITING_PAYMENT,
            OrderStatus.WASHING,
            OrderStatus.OUT_FOR_DELIVERY,
          ],
        },
      },
      include: ORDER_INCLUDE,
      orderBy: { updatedAt: 'desc' },
    });
    return res.json(order); // may be null
  } catch (error: unknown) {
    console.error('Error loading active delivery:', error);
    return res.status(500).json({ error: 'Failed to load active delivery.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/driver/profile — availability + vehicle info
// ---------------------------------------------------------------------------
router.get('/profile', async (req: Request, res: Response) => {
  try {
    const profile = await getOwnProfile(req.user!.id);
    if (!profile) return res.status(404).json({ error: 'No driver profile found.' });
    return res.json({
      id: profile.id,
      vehicleType: profile.vehicleType,
      plateNumber: profile.plateNumber,
      availability: profile.availability,
      latitude: profile.latitude,
      longitude: profile.longitude,
    });
  } catch (error: unknown) {
    console.error('Error loading driver profile:', error);
    return res.status(500).json({ error: 'Failed to load profile.' });
  }
});

export default router;
