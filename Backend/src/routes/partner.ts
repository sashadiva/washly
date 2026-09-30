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

    const updated = await prisma.order.update({
      where: { id: order.id },
      data: { status: target! },
      include: ORDER_INCLUDE,
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
        itemsSubtotal + order.deliveryFee - order.voucherDiscount
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

    const [paidOrders, totalOrders, completedOrders] = await Promise.all([
      prisma.order.findMany({ where: paidWhere, select: { finalTotal: true } }),
      prisma.order.count({ where: whereBase }),
      prisma.order.count({ where: { ...whereBase, status: OrderStatus.COMPLETED } }),
    ]);

    const revenue = paidOrders.reduce((sum, o) => sum + (o.finalTotal ?? 0), 0);

    return res.json({
      revenue,
      paidOrderCount: paidOrders.length,
      totalOrderCount: totalOrders,
      completedOrderCount: completedOrders,
    });
  } catch (error: unknown) {
    console.error('Error building dashboard:', error);
    return res.status(500).json({ error: 'Failed to load dashboard.' });
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
