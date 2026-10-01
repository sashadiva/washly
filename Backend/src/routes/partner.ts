import { Router, Request, Response } from 'express';
import {
  Prisma,
  PricingUnit,
  PaymentStatus,
  OrderStatus,
  WarrantyClaimStatus,
} from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { nextStatus, IllegalTransitionError } from '../services/orderStateMachine.js';
import { offerToNearestDriver } from '../services/assignmentService.js';

const router = Router();

// Every route here requires an authenticated PARTNER.
router.use(authGuard, roleGuard('PARTNER'));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

function toFiniteNumber(v: unknown): number | null {
  const n = typeof v === 'number' ? v : parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

/** Resolve the laundromat owned by the authenticated partner, or null. */
async function getOwnLaundromat(userId: number) {
  return prisma.laundromat.findUnique({ where: { ownerId: userId } });
}

/** Order include shared across partner responses (customer name for context). */
const ORDER_INCLUDE = {
  items: true,
  declaredItems: true,
  payments: { orderBy: { createdAt: 'desc' } },
  customer: { select: { id: true, name: true, phone: true } },
  // Assigned driver's vehicle (+ contact) so the laundromat knows who is
  // bringing the laundry in / taking it out. Null until a driver accepts a leg.
  driver: {
    select: {
      vehicleType: true,
      plateNumber: true,
      user: { select: { name: true, phone: true } },
    },
  },
} satisfies Prisma.OrderInclude;

/** Whether an order's required up-front charge is settled (per-item only). */
function hasSettledPayment(payments: { status: PaymentStatus }[]): boolean {
  return payments.some((p) => p.status === PaymentStatus.SETTLED);
}

// ---------------------------------------------------------------------------
// GET /api/partner/orders — orders for the partner's own laundromat
// ---------------------------------------------------------------------------
router.get('/orders', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) {
      return res.status(404).json({ error: 'No laundromat found for this partner.' });
    }
    const orders = await prisma.order.findMany({
      where: { laundromatId: shop.id },
      include: ORDER_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
    return res.json(orders);
  } catch (error: unknown) {
    console.error('Error fetching partner orders:', error);
    return res.status(500).json({ error: 'Failed to load orders.' });
  }
});

/**
 * Load an order and assert it belongs to the authenticated partner's shop.
 * Returns { order, shop } or sends a 404 and returns null.
 */
async function loadOwnedOrder(req: Request<{ id: string }>, res: Response) {
  const orderId = parseInt(req.params.id, 10);
  if (isNaN(orderId)) {
    res.status(400).json({ error: 'Invalid order ID.' });
    return null;
  }
  const shop = await getOwnLaundromat(req.user!.id);
  if (!shop) {
    res.status(404).json({ error: 'No laundromat found for this partner.' });
    return null;
  }
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: ORDER_INCLUDE,
  });
  if (!order || order.laundromatId !== shop.id) {
    res.status(404).json({ error: 'Order not found.' });
    return null;
  }
  return { order, shop };
}

function handleTransition(res: Response, fn: () => void): boolean {
  try {
    fn();
    return true;
  } catch (e) {
    if (e instanceof IllegalTransitionError) {
      res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      return false;
    }
    throw e;
  }
}

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/accept
// Per-item orders require a SETTLED payment before acceptance (design rule).
// ---------------------------------------------------------------------------
router.post('/orders/:id/accept', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    if (
      order.pricingModel === PricingUnit.PER_ITEM &&
      !hasSettledPayment(order.payments)
    ) {
      return res.status(409).json({
        error: 'Per-item orders must be paid before they can be accepted.',
        currentStatus: order.status,
      });
    }

    let target: OrderStatus | undefined;
    if (!handleTransition(res, () => {
      target = nextStatus('accept', order.status, 'PARTNER');
    })) return;

    const updated = await prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: order.id },
        data: { status: target! },
      });
      // Declared-item intake is NOT confirmed here. The partner hasn't seen the
      // items yet — they confirm receipt when the laundry physically arrives at
      // the laundromat (see /orders/:id/receive), which establishes warranty.
      return tx.order.findUnique({
        where: { id: order.id },
        include: ORDER_INCLUDE,
      });
    });

    // Order is now ACCEPTED: offer the pickup to the nearest available driver.
    await offerToNearestDriver(order.id, 'PICKUP');

    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error accepting order:', error);
    return res.status(500).json({ error: 'Failed to accept order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/reject  (-> CANCELLED)
// ---------------------------------------------------------------------------
router.post('/orders/:id/reject', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    let target: OrderStatus | undefined;
    if (!handleTransition(res, () => {
      target = nextStatus('reject', order.status, 'PARTNER');
    })) return;

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: target! },
      include: ORDER_INCLUDE,
    });
    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error rejecting order:', error);
    return res.status(500).json({ error: 'Failed to reject order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/weigh  (per-kg only)
// Sets weighedKg, computes the final price, -> WEIGHED_AWAITING_CONFIRM.
// ---------------------------------------------------------------------------
router.post('/orders/:id/weigh', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    if (order.pricingModel !== PricingUnit.PER_KG) {
      return res.status(400).json({ error: 'Only per-kg orders are weighed.' });
    }

    const weighedKg = toFiniteNumber(req.body?.weighedKg);
    if (weighedKg === null || weighedKg <= 0) {
      return res.status(400).json({ error: 'A positive weighedKg is required.' });
    }

    // Recompute line totals and the order total from the measured weight.
    // Per-kg items are priced at unitPrice * weighedKg (split evenly if the
    // cart holds multiple per-kg services).
    const perKgItems = order.items.filter((i) => i.unit === PricingUnit.PER_KG);
    const perItemItems = order.items.filter((i) => i.unit === PricingUnit.PER_ITEM);

    const kgShare = perKgItems.length > 0 ? weighedKg / perKgItems.length : 0;
    let itemsSubtotal = 0;

    const target: OrderStatus = (() => {
      let t: OrderStatus = order.status;
      // Validate the transition before mutating anything.
      t = nextStatus('enterWeight', order.status, 'PARTNER');
      return t;
    })();

    const updated = await prisma.$transaction(async (tx) => {
      for (const item of perKgItems) {
        const line = item.unitPrice * kgShare;
        itemsSubtotal += line;
        await tx.orderItem.update({
          where: { id: item.id },
          data: { lineTotal: line },
        });
      }
      for (const item of perItemItems) {
        const line = item.lineTotal ?? item.unitPrice * item.quantity;
        itemsSubtotal += line;
      }

      const finalTotal = Math.max(
        0,
        itemsSubtotal +
          order.deliveryFee +
          order.declaredItemsFee -
          order.voucherDiscount
      );

      return tx.order.update({
        where: { id: order.id },
        data: {
          weighedKg,
          itemsSubtotal,
          finalTotal,
          status: target,
        },
        include: ORDER_INCLUDE,
      });
    });

    return res.json(updated);
  } catch (error: unknown) {
    if (error instanceof IllegalTransitionError) {
      return res
        .status(409)
        .json({ error: error.message, currentStatus: error.currentStatus });
    }
    console.error('Error weighing order:', error);
    return res.status(500).json({ error: 'Failed to record weight.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/receive  (AT_LAUNDROMAT -> next)
// The combined "receive & weigh" step the partner performs when the laundry
// arrives at the shop. In one call it:
//   1. Confirms declared-item intake (or flags discrepancies) — establishes
//      warranty coverage.
//   2. Per-kg: records the weight, computes the price -> WEIGHED_AWAITING_CONFIRM.
//      Per-item: advances to WASHING (already paid at checkout).
// Body: {
//   weighedKg?: number,                                   // required for per-kg
//   intake?: [{ declaredItemId, confirmed: bool, discrepancyNote?: string }]
// }
// ---------------------------------------------------------------------------
router.post('/orders/:id/receive', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    if (order.status !== OrderStatus.AT_LAUNDROMAT) {
      return res.status(409).json({
        error: 'The laundry must be at the laundromat before you can receive it.',
        currentStatus: order.status,
      });
    }

    const isKilo = order.pricingModel === PricingUnit.PER_KG;

    // Validate weight up front for per-kg so we don't partially apply intake.
    const weighedKg = toFiniteNumber(req.body?.weighedKg);
    if (isKilo && (weighedKg === null || weighedKg <= 0)) {
      return res.status(400).json({ error: 'A positive weighedKg is required.' });
    }

    // Resolve the target status via the state machine before mutating.
    let target: OrderStatus;
    try {
      target = isKilo
        ? nextStatus('enterWeight', order.status, 'PARTNER')
        : nextStatus('confirmPayment', order.status, 'SYSTEM');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    const declaredIds = new Set(order.declaredItems.map((d) => d.id));
    const intake = Array.isArray(req.body?.intake) ? req.body.intake : [];

    const updated = await prisma.$transaction(async (tx) => {
      // 1. Apply declared-item intake. Any declared item not mentioned defaults
      //    to confirmed received (the partner accepted the bag as-is).
      const mentioned = new Set<number>();
      for (const raw of intake) {
        const did = parseInt(String(raw?.declaredItemId), 10);
        if (isNaN(did) || !declaredIds.has(did)) continue;
        mentioned.add(did);
        await tx.declaredItem.update({
          where: { id: did },
          data: {
            confirmedReceived: Boolean(raw?.confirmed),
            discrepancyNote:
              typeof raw?.discrepancyNote === 'string' &&
              raw.discrepancyNote.trim().length > 0
                ? raw.discrepancyNote.trim()
                : null,
          },
        });
      }
      // Unmentioned declared items are treated as received.
      const unmentioned = [...declaredIds].filter((id) => !mentioned.has(id));
      if (unmentioned.length > 0) {
        await tx.declaredItem.updateMany({
          where: { id: { in: unmentioned } },
          data: { confirmedReceived: true },
        });
      }

      // 2. Per-kg: weigh + price. Per-item: just advance.
      const data: Prisma.OrderUpdateInput = { status: target };
      if (isKilo) {
        const perKgItems = order.items.filter((i) => i.unit === PricingUnit.PER_KG);
        const perItemItems = order.items.filter((i) => i.unit === PricingUnit.PER_ITEM);
        const kgShare = perKgItems.length > 0 ? weighedKg! / perKgItems.length : 0;
        let itemsSubtotal = 0;
        for (const item of perKgItems) {
          const line = item.unitPrice * kgShare;
          itemsSubtotal += line;
          await tx.orderItem.update({ where: { id: item.id }, data: { lineTotal: line } });
        }
        for (const item of perItemItems) {
          itemsSubtotal += item.lineTotal ?? item.unitPrice * item.quantity;
        }
        data.weighedKg = weighedKg!;
        data.itemsSubtotal = itemsSubtotal;
        data.finalTotal = Math.max(
          0,
          itemsSubtotal + order.deliveryFee + order.declaredItemsFee - order.voucherDiscount
        );
      }

      return tx.order.update({
        where: { id: order.id },
        data,
        include: ORDER_INCLUDE,
      });
    });

    return res.json(updated);
  } catch (error: unknown) {
    if (error instanceof IllegalTransitionError) {
      return res.status(409).json({ error: error.message, currentStatus: error.currentStatus });
    }
    console.error('Error receiving order:', error);
    return res.status(500).json({ error: 'Failed to receive order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/ready  (WASHING -> READY_FOR_DELIVERY)
// ---------------------------------------------------------------------------
router.post('/orders/:id/ready', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    let target: OrderStatus | undefined;
    if (!handleTransition(res, () => {
      target = nextStatus('markReady', order.status, 'PARTNER');
    })) return;

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: target! },
      include: ORDER_INCLUDE,
    });

    // Order is READY_FOR_DELIVERY: offer the delivery leg to nearest driver.
    await offerToNearestDriver(order.id, 'DELIVERY');

    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error marking order ready:', error);
    return res.status(500).json({ error: 'Failed to update order.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/partner/profile — the partner's own laundromat
// ---------------------------------------------------------------------------
router.get('/profile', async (req: Request, res: Response) => {
  try {
    const shop = await prisma.laundromat.findUnique({
      where: { ownerId: req.user!.id },
      include: { tags: { include: { tag: true } } },
    });
    if (!shop) {
      return res.status(404).json({ error: 'No laundromat found for this partner.' });
    }
    return res.json({
      id: shop.id,
      name: shop.name,
      description: shop.description,
      address: shop.address, // partner sees their own exact address
      areaLabel: shop.areaLabel,
      latitude: shop.latitude,
      longitude: shop.longitude,
      imageUrl: shop.imageUrl,
      rating: shop.rating,
      reviewCount: shop.reviewCount,
      isOpen: shop.isOpen,
      specialties: shop.tags.map((t) => t.tag.name),
    });
  } catch (error: unknown) {
    console.error('Error fetching partner profile:', error);
    return res.status(500).json({ error: 'Failed to load profile.' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/partner/profile — edit own shop (name, description, image,
// specialties, coords, areaLabel, address, isOpen)
// ---------------------------------------------------------------------------
router.put('/profile', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) {
      return res.status(404).json({ error: 'No laundromat found for this partner.' });
    }

    const {
      name,
      description,
      address,
      areaLabel,
      latitude,
      longitude,
      imageUrl,
      isOpen,
      specialties,
    } = req.body ?? {};

    const data: Prisma.LaundromatUpdateInput = {};
    if (name !== undefined) {
      if (!isNonEmptyString(name)) return res.status(400).json({ error: 'name cannot be empty.' });
      data.name = name.trim();
    }
    if (description !== undefined) data.description = description === null ? null : String(description);
    if (address !== undefined) {
      if (!isNonEmptyString(address)) return res.status(400).json({ error: 'address cannot be empty.' });
      data.address = address.trim();
    }
    if (areaLabel !== undefined) data.areaLabel = areaLabel === null ? null : String(areaLabel);
    if (imageUrl !== undefined) data.imageUrl = imageUrl === null ? null : String(imageUrl);
    if (isOpen !== undefined) data.isOpen = Boolean(isOpen);
    if (latitude !== undefined) {
      const lat = toFiniteNumber(latitude);
      if (lat === null) return res.status(400).json({ error: 'latitude must be a number.' });
      data.latitude = lat;
    }
    if (longitude !== undefined) {
      const lng = toFiniteNumber(longitude);
      if (lng === null) return res.status(400).json({ error: 'longitude must be a number.' });
      data.longitude = lng;
    }

    await prisma.$transaction(async (tx) => {
      await tx.laundromat.update({ where: { id: shop.id }, data });

      // Replace specialty tags when provided.
      if (specialties !== undefined) {
        let list: string[] = [];
        if (Array.isArray(specialties)) {
          list = specialties.map((s) => String(s).trim().toLowerCase()).filter(Boolean);
        } else if (isNonEmptyString(specialties)) {
          list = specialties.split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
        }
        await tx.laundromatsOnTags.deleteMany({ where: { laundromatId: shop.id } });
        for (const tagName of list) {
          const tag = await tx.tag.upsert({
            where: { name: tagName },
            update: {},
            create: { name: tagName },
          });
          await tx.laundromatsOnTags.create({
            data: { laundromatId: shop.id, tagId: tag.id },
          });
        }
      }
    });

    const refreshed = await prisma.laundromat.findUnique({
      where: { id: shop.id },
      include: { tags: { include: { tag: true } } },
    });
    return res.json({
      id: refreshed!.id,
      name: refreshed!.name,
      description: refreshed!.description,
      address: refreshed!.address,
      areaLabel: refreshed!.areaLabel,
      latitude: refreshed!.latitude,
      longitude: refreshed!.longitude,
      imageUrl: refreshed!.imageUrl,
      isOpen: refreshed!.isOpen,
      specialties: refreshed!.tags.map((t) => t.tag.name),
    });
  } catch (error: unknown) {
    console.error('Error updating partner profile:', error);
    return res.status(500).json({ error: 'Failed to update profile.' });
  }
});

// ---------------------------------------------------------------------------
// Services CRUD (own laundromat only)
// ---------------------------------------------------------------------------
router.get('/services', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });
    const services = await prisma.laundryService.findMany({
      where: { laundromatId: shop.id },
      orderBy: { id: 'asc' },
    });
    return res.json(services);
  } catch (error: unknown) {
    console.error('Error listing services:', error);
    return res.status(500).json({ error: 'Failed to load services.' });
  }
});

router.post('/services', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const { name, description, price, unit, imageUrl } = req.body ?? {};
    if (!isNonEmptyString(name)) return res.status(400).json({ error: 'name is required.' });
    const parsedPrice = toFiniteNumber(price);
    if (parsedPrice === null || parsedPrice < 0) {
      return res.status(400).json({ error: 'A valid non-negative price is required.' });
    }
    const unitEnum = String(unit ?? '').toUpperCase();
    if (!Object.values(PricingUnit).includes(unitEnum as PricingUnit)) {
      return res.status(400).json({
        error: `unit must be one of: ${Object.values(PricingUnit).join(', ')}`,
      });
    }

    const service = await prisma.laundryService.create({
      data: {
        name: name.trim(),
        description: isNonEmptyString(description) ? description.trim() : null,
        price: parsedPrice,
        unit: unitEnum as PricingUnit,
        imageUrl: isNonEmptyString(imageUrl) ? imageUrl.trim() : null,
        laundromatId: shop.id,
      },
    });
    return res.status(201).json(service);
  } catch (error: unknown) {
    console.error('Error creating service:', error);
    return res.status(500).json({ error: 'Failed to create service.' });
  }
});

router.put('/services/:id', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });
    const serviceId = parseInt(req.params.id, 10);
    if (isNaN(serviceId)) return res.status(400).json({ error: 'Invalid service ID.' });

    const existing = await prisma.laundryService.findUnique({ where: { id: serviceId } });
    if (!existing || existing.laundromatId !== shop.id) {
      return res.status(404).json({ error: 'Service not found.' });
    }

    const { name, description, price, unit, imageUrl } = req.body ?? {};
    const data: Prisma.LaundryServiceUpdateInput = {};
    if (name !== undefined) {
      if (!isNonEmptyString(name)) return res.status(400).json({ error: 'name cannot be empty.' });
      data.name = name.trim();
    }
    if (description !== undefined) {
      data.description = isNonEmptyString(description) ? description.trim() : null;
    }
    if (price !== undefined) {
      const parsedPrice = toFiniteNumber(price);
      if (parsedPrice === null || parsedPrice < 0) {
        return res.status(400).json({ error: 'A valid non-negative price is required.' });
      }
      data.price = parsedPrice;
    }
    if (unit !== undefined) {
      const unitEnum = String(unit).toUpperCase();
      if (!Object.values(PricingUnit).includes(unitEnum as PricingUnit)) {
        return res.status(400).json({
          error: `unit must be one of: ${Object.values(PricingUnit).join(', ')}`,
        });
      }
      data.unit = unitEnum as PricingUnit;
    }
    if (imageUrl !== undefined) {
      data.imageUrl = isNonEmptyString(imageUrl) ? imageUrl.trim() : null;
    }

    const updated = await prisma.laundryService.update({ where: { id: serviceId }, data });
    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error updating service:', error);
    return res.status(500).json({ error: 'Failed to update service.' });
  }
});

router.delete('/services/:id', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });
    const serviceId = parseInt(req.params.id, 10);
    if (isNaN(serviceId)) return res.status(400).json({ error: 'Invalid service ID.' });

    const existing = await prisma.laundryService.findUnique({ where: { id: serviceId } });
    if (!existing || existing.laundromatId !== shop.id) {
      return res.status(404).json({ error: 'Service not found.' });
    }

    await prisma.laundryService.delete({ where: { id: serviceId } });
    return res.json({ message: 'Service deleted.' });
  } catch (error: unknown) {
    console.error('Error deleting service:', error);
    return res.status(500).json({ error: 'Failed to delete service.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/partner/dashboard?from=&to= — revenue + counts from own PAID orders
// ---------------------------------------------------------------------------
router.get('/dashboard', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const { from, to } = req.query as { from?: string; to?: string };
    const createdAt: Prisma.DateTimeFilter = {};
    if (from) {
      const d = new Date(from);
      if (!isNaN(d.getTime())) createdAt.gte = d;
    }
    if (to) {
      const d = new Date(to);
      if (!isNaN(d.getTime())) createdAt.lte = d;
    }

    const whereBase: Prisma.OrderWhereInput = { laundromatId: shop.id };
    if (createdAt.gte || createdAt.lte) whereBase.createdAt = createdAt;

    // "Paid" = order has a SETTLED payment.
    const paidWhere: Prisma.OrderWhereInput = {
      ...whereBase,
      payments: { some: { status: PaymentStatus.SETTLED } },
    };

    // "In process" = active (not completed, not cancelled, not just placed-
    // unpaid). We treat anything that's been accepted and is still moving as
    // in process.
    const inProcessStatuses: OrderStatus[] = [
      OrderStatus.ACCEPTED,
      OrderStatus.DRIVER_ASSIGNED,
      OrderStatus.PICKED_UP,
      OrderStatus.WEIGHED_AWAITING_CONFIRM,
      OrderStatus.AWAITING_PAYMENT,
      OrderStatus.WASHING,
      OrderStatus.READY_FOR_DELIVERY,
      OrderStatus.OUT_FOR_DELIVERY,
    ];

    const [paidOrders, totalOrders, completedOrders, inProcessOrders, cancelledOrders] =
      await Promise.all([
        prisma.order.findMany({ where: paidWhere, select: { finalTotal: true } }),
        prisma.order.count({ where: whereBase }),
        prisma.order.count({ where: { ...whereBase, status: OrderStatus.COMPLETED } }),
        prisma.order.count({ where: { ...whereBase, status: { in: inProcessStatuses } } }),
        prisma.order.count({ where: { ...whereBase, status: OrderStatus.CANCELLED } }),
      ]);

    const revenue = paidOrders.reduce((sum, o) => sum + (o.finalTotal ?? 0), 0);

    return res.json({
      revenue,
      paidOrderCount: paidOrders.length,
      totalOrderCount: totalOrders,
      completedOrderCount: completedOrders,
      inProcessOrderCount: inProcessOrders,
      cancelledOrderCount: cancelledOrders,
    });
  } catch (error: unknown) {
    console.error('Error building dashboard:', error);
    return res.status(500).json({ error: 'Failed to load dashboard.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/partner/reviews — all reviews for the partner's own shop
// ---------------------------------------------------------------------------
router.get('/reviews', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const reviews = await prisma.review.findMany({
      where: { laundromatId: shop.id },
      include: { user: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return res.json(
      reviews.map((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment,
        userName: r.user.name,
        createdAt: r.createdAt,
      }))
    );
  } catch (error: unknown) {
    console.error('Error loading partner reviews:', error);
    return res.status(500).json({ error: 'Failed to load reviews.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/partner/report?from=&to= — a sales report payload for export.
// Summary + per-service (per-product) breakdown + status counts. Only paid
// orders count toward revenue.
// ---------------------------------------------------------------------------
router.get('/report', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const { from, to } = req.query as { from?: string; to?: string };
    const createdAt: Prisma.DateTimeFilter = {};
    if (from) {
      const d = new Date(from);
      if (!isNaN(d.getTime())) createdAt.gte = d;
    }
    if (to) {
      const d = new Date(to);
      if (!isNaN(d.getTime())) createdAt.lte = d;
    }
    const whereBase: Prisma.OrderWhereInput = { laundromatId: shop.id };
    if (createdAt.gte || createdAt.lte) whereBase.createdAt = createdAt;

    const orders = await prisma.order.findMany({
      where: whereBase,
      include: { items: true, payments: true },
      orderBy: { createdAt: 'asc' },
    });

    // Status counts.
    const statusCounts: Record<string, number> = {};
    for (const o of orders) {
      statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    }

    const paid = orders.filter((o) =>
      o.payments.some((p) => p.status === PaymentStatus.SETTLED)
    );
    const revenue = paid.reduce((sum, o) => sum + (o.finalTotal ?? 0), 0);

    // Per-service (per-product) breakdown — only from paid orders so revenue
    // reconciles with the summary.
    const byService = new Map<
      string,
      { serviceName: string; unit: string; orders: number; quantity: number; revenue: number }
    >();
    for (const o of paid) {
      for (const it of o.items) {
        const key = `${it.serviceName}__${it.unit}`;
        const row =
          byService.get(key) ??
          { serviceName: it.serviceName, unit: it.unit, orders: 0, quantity: 0, revenue: 0 };
        row.orders += 1;
        row.quantity += it.quantity;
        row.revenue += it.lineTotal ?? 0;
        byService.set(key, row);
      }
    }

    return res.json({
      shopName: shop.name,
      generatedAt: new Date().toISOString(),
      from: createdAt.gte ? (createdAt.gte as Date).toISOString() : null,
      to: createdAt.lte ? (createdAt.lte as Date).toISOString() : null,
      summary: {
        revenue,
        totalOrders: orders.length,
        paidOrders: paid.length,
        completedOrders: statusCounts[OrderStatus.COMPLETED] ?? 0,
        cancelledOrders: statusCounts[OrderStatus.CANCELLED] ?? 0,
        averageOrderValue: paid.length > 0 ? revenue / paid.length : 0,
      },
      perService: Array.from(byService.values()).sort((a, b) => b.revenue - a.revenue),
      orders: orders.map((o) => ({
        id: o.id,
        date: o.createdAt.toISOString(),
        status: o.status,
        total: o.finalTotal ?? 0,
      })),
    });
  } catch (error: unknown) {
    console.error('Error building report:', error);
    return res.status(500).json({ error: 'Failed to build report.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/orders/:id/intake — confirm declared items received (or
// flag a discrepancy). Only the owning partner; enables later warranty claims.
// Body: { items: [{ declaredItemId, confirmed: bool, discrepancyNote?: string }] }
// ---------------------------------------------------------------------------
router.post('/orders/:id/intake', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const loaded = await loadOwnedOrder(req, res);
    if (!loaded) return;
    const { order } = loaded;

    const items = req.body?.items;
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'items array is required.' });
    }

    const declaredIds = new Set(order.declaredItems.map((d) => d.id));

    await prisma.$transaction(async (tx) => {
      for (const raw of items) {
        const id = parseInt(String(raw?.declaredItemId), 10);
        if (isNaN(id) || !declaredIds.has(id)) continue; // ignore unknown ids
        await tx.declaredItem.update({
          where: { id },
          data: {
            confirmedReceived: Boolean(raw?.confirmed),
            discrepancyNote:
              typeof raw?.discrepancyNote === 'string' && raw.discrepancyNote.trim().length > 0
                ? raw.discrepancyNote.trim()
                : null,
          },
        });
      }
    });

    const refreshed = await prisma.order.findUnique({
      where: { id: order.id },
      include: ORDER_INCLUDE,
    });
    return res.json(refreshed);
  } catch (error: unknown) {
    console.error('Error confirming intake:', error);
    return res.status(500).json({ error: 'Failed to confirm intake.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/partner/claims — warranty claims against the partner's orders
// ---------------------------------------------------------------------------
router.get('/claims', async (req: Request, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const claims = await prisma.warrantyClaim.findMany({
      where: { order: { laundromatId: shop.id } },
      include: { declaredItem: true, order: { select: { id: true, customerId: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(claims);
  } catch (error: unknown) {
    console.error('Error loading partner claims:', error);
    return res.status(500).json({ error: 'Failed to load claims.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/partner/claims/:id/resolve — only the order's partner may resolve.
// Body: { status: 'APPROVED'|'REJECTED'|'RESOLVED', note?, payoutAmount? }
// Payout is attributed to Washly (platform), informational only.
// ---------------------------------------------------------------------------
router.post('/claims/:id/resolve', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const shop = await getOwnLaundromat(req.user!.id);
    if (!shop) return res.status(404).json({ error: 'No laundromat found for this partner.' });

    const claimId = parseInt(req.params.id, 10);
    if (isNaN(claimId)) return res.status(400).json({ error: 'Invalid claim ID.' });

    const claim = await prisma.warrantyClaim.findUnique({
      where: { id: claimId },
      include: { order: true },
    });
    if (!claim || claim.order.laundromatId !== shop.id) {
      return res.status(404).json({ error: 'Claim not found.' });
    }

    const { status, note, payoutAmount } = req.body ?? {};
    const statusEnum = String(status ?? '').toUpperCase();
    const allowed: string[] = [
      WarrantyClaimStatus.APPROVED,
      WarrantyClaimStatus.REJECTED,
      WarrantyClaimStatus.RESOLVED,
    ];
    if (!allowed.includes(statusEnum)) {
      return res.status(400).json({ error: `status must be one of: ${allowed.join(', ')}` });
    }

    const payout = toFiniteNumber(payoutAmount);

    const updated = await prisma.warrantyClaim.update({
      where: { id: claimId },
      data: {
        status: statusEnum as WarrantyClaimStatus,
        resolutionNote: typeof note === 'string' && note.trim().length > 0 ? note.trim() : null,
        payoutAmount: statusEnum === WarrantyClaimStatus.REJECTED ? null : payout,
        payoutFundedBy: 'WASHLY',
      },
    });
    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error resolving claim:', error);
    return res.status(500).json({ error: 'Failed to resolve claim.' });
  }
});

export default router;
