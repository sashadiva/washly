import { Router, Request, Response } from 'express';
import { Prisma, PricingUnit, OrderStatus, WarrantyClaimStatus } from '@prisma/client';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';
import { getDistanceKm } from '../services/distanceService.js';
import { feeFor } from '../services/deliveryFeeService.js';
import { nextStatus, IllegalTransitionError } from '../services/orderStateMachine.js';
import { DECLARED_ITEMS_FEE } from '../services/pricing.js';

const router = Router();

// Every route here is customer-scoped.
router.use(authGuard, roleGuard('CUSTOMER'));

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CartItemInput {
  serviceId: number | string;
  quantity: number | string; // pieces (per-item) or estimated kg (per-kg)
  notes?: string;
}

interface DeclaredItemInput {
  label: string;
  photoUrl: string;
}

interface CreateOrderBody {
  laundromatId: number | string;
  pickupAddress: string;
  deliveryAddress?: string;
  notes?: string;
  customerLat?: number | string;
  customerLng?: number | string;
  items: CartItemInput[];
  declaredItems?: DeclaredItemInput[];
  voucherId?: number | string;
}

// ---------------------------------------------------------------------------
// Response shaping
// ---------------------------------------------------------------------------

/**
 * Full order shape returned to the customer: items, timeline-ready status,
 * and receipt fields. Never leaks the laundromat's exact address/coords.
 */
const ORDER_INCLUDE = {
  items: true,
  declaredItems: true,
  payments: { orderBy: { createdAt: 'desc' } },
  appliedVoucher: true,
  laundromat: {
    select: { id: true, name: true, areaLabel: true, imageUrl: true },
  },
  // Assigned driver's vehicle (+ contact) so the customer can identify who is
  // picking up / delivering. Null until a driver accepts a leg.
  driver: {
    select: {
      vehicleType: true,
      plateNumber: true,
      user: { select: { name: true, phone: true } },
    },
  },
} satisfies Prisma.OrderInclude;

// ---------------------------------------------------------------------------
// POST /api/orders — create an order from the customer's cart
// ---------------------------------------------------------------------------
router.post('/', async (req: Request<{}, {}, CreateOrderBody>, res: Response) => {
  try {
    const customerId = req.user!.id;
    const {
      laundromatId,
      pickupAddress,
      deliveryAddress,
      notes,
      customerLat,
      customerLng,
      items,
      declaredItems,
      voucherId,
    } = req.body ?? {};

    const parsedLaundromatId = parseInt(String(laundromatId), 10);
    if (isNaN(parsedLaundromatId)) {
      return res.status(400).json({ error: 'A valid laundromatId is required.' });
    }
    if (!pickupAddress || String(pickupAddress).trim().length === 0) {
      return res.status(400).json({ error: 'pickupAddress is required.' });
    }
    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'At least one cart item is required.' });
    }

    const store = await prisma.laundromat.findUnique({
      where: { id: parsedLaundromatId },
      include: { services: true },
    });
    if (!store) {
      return res.status(404).json({ error: 'Laundromat not found.' });
    }

    // Resolve each cart item against a real service on this laundromat, taking
    // price/unit snapshots so the receipt stays stable if the partner edits
    // services later.
    const serviceById = new Map(store.services.map((s) => [s.id, s]));
    const orderItemsData: Prisma.OrderItemCreateWithoutOrderInput[] = [];

    for (const raw of items) {
      const serviceId = parseInt(String(raw.serviceId), 10);
      const quantity = parseFloat(String(raw.quantity));
      if (isNaN(serviceId) || !serviceById.has(serviceId)) {
        return res.status(400).json({ error: `Unknown serviceId in cart: ${raw.serviceId}` });
      }
      if (!Number.isFinite(quantity) || quantity <= 0) {
        return res.status(400).json({ error: 'Each cart item needs a positive quantity.' });
      }
      const service = serviceById.get(serviceId)!;
      // Per-item: line total known now. Per-kg: unknown until weigh-in (null).
      const lineTotal = service.unit === PricingUnit.PER_ITEM ? service.price * quantity : null;

      orderItemsData.push({
        serviceId: service.id,
        serviceName: service.name,
        unit: service.unit,
        unitPrice: service.price,
        quantity,
        lineTotal,
        notes: raw.notes && raw.notes.trim().length > 0 ? raw.notes.trim() : null,
      });
    }

    // The order's pricing model is the model of the items in the cart. A cart
    // mixing PER_KG and PER_ITEM is treated as PER_KG (needs weigh-in) so the
    // customer is never charged a partial total up front.
    const hasPerKg = orderItemsData.some((i) => i.unit === PricingUnit.PER_KG);
    const pricingModel: PricingUnit = hasPerKg ? PricingUnit.PER_KG : PricingUnit.PER_ITEM;

    // Distance + delivery fee from customer coords (when supplied).
    const lat = customerLat != null ? parseFloat(String(customerLat)) : null;
    const lng = customerLng != null ? parseFloat(String(customerLng)) : null;
    let distanceKm: number | null = null;
    if (lat != null && lng != null && Number.isFinite(lat) && Number.isFinite(lng)) {
      distanceKm = parseFloat(getDistanceKm(lat, lng, store.latitude, store.longitude).toFixed(1));
    }
    const deliveryFee = feeFor(distanceKm ?? 0);

    // Optional voucher: must belong to the customer, be unused, unexpired.
    let voucherDiscount = 0;
    let appliedVoucherId: number | null = null;
    const parsedVoucherId = voucherId != null ? parseInt(String(voucherId), 10) : null;
    if (parsedVoucherId != null && !isNaN(parsedVoucherId)) {
      const voucher = await prisma.voucher.findUnique({ where: { id: parsedVoucherId } });
      if (!voucher || voucher.userId !== customerId || voucher.used) {
        return res.status(400).json({ error: 'Voucher is invalid or already used.' });
      }
      voucherDiscount = voucher.amountOff;
      appliedVoucherId = voucher.id;
    }

    // Declared items for the warranty window (photos captured at checkout).
    const declaredItemsData: Prisma.DeclaredItemCreateWithoutOrderInput[] = Array.isArray(
      declaredItems
    )
      ? declaredItems
          .filter((d) => d && typeof d.label === 'string' && typeof d.photoUrl === 'string')
          .map((d) => ({ label: d.label.trim(), photoUrl: d.photoUrl }))
      : [];

    // Flat one-time protection fee when the order carries declared items.
    const declaredItemsFee = declaredItemsData.length > 0 ? DECLARED_ITEMS_FEE : 0;

    // Per-item: subtotal + final total known now (subtotal + fees - voucher,
    // floored at 0). Per-kg: subtotal/final left null until weigh-in.
    let itemsSubtotal: number | null = null;
    let finalTotal: number | null = null;
    if (pricingModel === PricingUnit.PER_ITEM) {
      itemsSubtotal = orderItemsData.reduce((sum, i) => sum + (i.lineTotal ?? 0), 0);
      finalTotal = Math.max(
        0,
        itemsSubtotal + deliveryFee + declaredItemsFee - voucherDiscount
      );
    }

    const order = await prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          status: OrderStatus.PENDING_ACCEPTANCE,
          pricingModel,
          pickupAddress: String(pickupAddress).trim(),
          deliveryAddress:
            deliveryAddress && String(deliveryAddress).trim().length > 0
              ? String(deliveryAddress).trim()
              : String(pickupAddress).trim(),
          notes: notes && String(notes).trim().length > 0 ? String(notes).trim() : null,
          customerLat: lat,
          customerLng: lng,
          distanceKm,
          deliveryFee,
          declaredItemsFee,
          itemsSubtotal,
          finalTotal,
          voucherDiscount,
          customerId,
          laundromatId: store.id,
          appliedVoucherId,
          items: { create: orderItemsData },
          declaredItems:
            declaredItemsData.length > 0 ? { create: declaredItemsData } : undefined,
        },
        include: ORDER_INCLUDE,
      });

      // Mark the voucher used (single-use) inside the same transaction.
      if (appliedVoucherId != null) {
        await tx.voucher.update({
          where: { id: appliedVoucherId },
          data: { used: true, usedAt: new Date() },
        });
      }

      return created;
    });

    return res.status(201).json(order);
  } catch (error: unknown) {
    console.error('Error creating order:', error);
    const detail = error instanceof Error ? error.message : String(error);
    return res.status(500).json({ error: 'Failed to create order.', detail });
  }
});

// ---------------------------------------------------------------------------
// GET /api/orders/mine — the authenticated customer's orders (list)
// ---------------------------------------------------------------------------
router.get('/mine', async (req: Request, res: Response) => {
  try {
    const orders = await prisma.order.findMany({
      where: { customerId: req.user!.id },
      include: ORDER_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
    return res.json(orders);
  } catch (error: unknown) {
    console.error('Error fetching orders:', error);
    return res.status(500).json({ error: 'Failed to load orders.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/orders/:id — a single order the customer owns (full detail)
// ---------------------------------------------------------------------------
router.get('/:id', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });

    // Owner-scoped: a 404 for both missing and not-owned avoids leaking IDs.
    if (!order || order.customerId !== req.user!.id) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    return res.json(order);
  } catch (error: unknown) {
    console.error('Error fetching order:', error);
    return res.status(500).json({ error: 'Failed to load order.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/orders/:id/approve-weight — customer approves the weighed price
// (per-kg only): WEIGHED_AWAITING_CONFIRM -> AWAITING_PAYMENT
// ---------------------------------------------------------------------------
router.post('/:id/approve-weight', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.customerId !== req.user!.id) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    let target: OrderStatus;
    try {
      target = nextStatus('approveWeight', order.status, 'CUSTOMER');
    } catch (e) {
      if (e instanceof IllegalTransitionError) {
        return res.status(409).json({ error: e.message, currentStatus: e.currentStatus });
      }
      throw e;
    }

    const updated = await prisma.order.update({
      where: { id: orderId },
      data: { status: target },
      include: ORDER_INCLUDE,
    });

    return res.json(updated);
  } catch (error: unknown) {
    console.error('Error approving weight:', error);
    return res.status(500).json({ error: 'Failed to approve weight.' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/orders/:id/claims — file a warranty claim (customer, owner-only)
// Gated: only against a declared item the partner CONFIRMED at intake, on a
// COMPLETED order owned by the claimant.
// ---------------------------------------------------------------------------
router.post('/:id/claims', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    const { declaredItemId, description, photoUrls } = req.body ?? {};
    const parsedItemId = parseInt(String(declaredItemId), 10);
    if (isNaN(parsedItemId)) {
      return res.status(400).json({ error: 'declaredItemId is required.' });
    }
    if (typeof description !== 'string' || description.trim().length === 0) {
      return res.status(400).json({ error: 'description is required.' });
    }
    const photos: string[] = Array.isArray(photoUrls)
      ? photoUrls.filter((p) => typeof p === 'string')
      : [];

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { declaredItems: true },
    });
    if (!order || order.customerId !== req.user!.id) {
      return res.status(404).json({ error: 'Order not found.' });
    }
    if (order.status !== OrderStatus.COMPLETED) {
      return res
        .status(409)
        .json({ error: 'Claims can only be filed on completed orders.' });
    }

    const item = order.declaredItems.find((d) => d.id === parsedItemId);
    if (!item) {
      return res.status(404).json({ error: 'Declared item not found on this order.' });
    }
    if (!item.confirmedReceived) {
      return res.status(409).json({
        error: 'Claims are only allowed on items the laundromat confirmed at intake.',
      });
    }

    const claim = await prisma.warrantyClaim.create({
      data: {
        orderId,
        declaredItemId: parsedItemId,
        description: description.trim(),
        photoUrls: photos,
        status: WarrantyClaimStatus.SUBMITTED,
      },
    });
    return res.status(201).json(claim);
  } catch (error: unknown) {
    console.error('Error filing claim:', error);
    return res.status(500).json({ error: 'Failed to file claim.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/orders/:id/claims — the customer views their claims for an order
// ---------------------------------------------------------------------------
router.get('/:id/claims', async (req: Request<{ id: string }>, res: Response) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.customerId !== req.user!.id) {
      return res.status(404).json({ error: 'Order not found.' });
    }
    const claims = await prisma.warrantyClaim.findMany({
      where: { orderId },
      include: { declaredItem: true },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(claims);
  } catch (error: unknown) {
    console.error('Error loading claims:', error);
    return res.status(500).json({ error: 'Failed to load claims.' });
  }
});

export default router;
