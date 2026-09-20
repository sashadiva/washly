import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { OrderStatus } from '@prisma/client';

const router = Router();

interface CreateOrderBody {
  customerId: number | string;
  laundromatId: number | string;
  pickupAddress: string;
  deliveryAddress?: string;
  serviceType: string;
  notes?: string;
  estimatedKg?: number | string;
}

interface UpdateOrderStatusBody {
  status: OrderStatus;
}

// ---------------------------------------------------------------------------
// POST /api/orders (Create a new Pickup & Delivery Order)
// ---------------------------------------------------------------------------
router.post('/', async (req: Request<{}, {}, CreateOrderBody>, res: Response) => {
  try {
    const {
      customerId,
      laundromatId,
      pickupAddress,
      deliveryAddress,
      serviceType,
      notes,
      estimatedKg,
    } = req.body;

    const parsedCustomerId = parseInt(String(customerId), 10);
    const parsedLaundromatId = parseInt(String(laundromatId), 10);

    if (isNaN(parsedCustomerId) || isNaN(parsedLaundromatId)) {
      return res.status(400).json({ error: 'Valid customerId and laundromatId are required.' });
    }

    if (!pickupAddress || !serviceType) {
      return res.status(400).json({ error: 'pickupAddress and serviceType are required.' });
    }

    // Verify Laundromat exists
    const store = await prisma.laundromat.findUnique({
      where: { id: parsedLaundromatId },
    });

    if (!store) {
      return res.status(404).json({ error: 'Laundromat not found.' });
    }

    const newOrder = await prisma.order.create({
      data: {
        customerId: parsedCustomerId,
        laundromatId: parsedLaundromatId,
        pickupAddress,
        deliveryAddress: deliveryAddress && deliveryAddress.trim().length > 0 ? deliveryAddress : pickupAddress,
        serviceType,
        notes: notes || null,
        estimatedKg: estimatedKg ? parseFloat(String(estimatedKg)) : null,
        status: OrderStatus.PICKUP_REQUESTED,
      },
      include: {
        laundromat: {
          select: {
            id: true,
            name: true,
            address: true,
            imageUrl: true,
          },
        },
      },
    });

    res.status(201).json(newOrder);
  } catch (error: any) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: error.message });
  }
});

// ---------------------------------------------------------------------------
// GET /api/orders/customer/:customerId (Get Orders by Customer)
// ---------------------------------------------------------------------------
router.get('/customer/:customerId', async (req: Request<{ customerId: string }>, res: Response) => {
  try {
    const customerId = parseInt(req.params.customerId, 10);

    if (isNaN(customerId)) {
      return res.status(400).json({ error: 'Invalid customer ID.' });
    }

    const orders = await prisma.order.findMany({
      where: { customerId },
      include: {
        laundromat: {
          select: {
            id: true,
            name: true,
            address: true,
            imageUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(orders);
  } catch (error: any) {
    console.error('Error fetching customer orders:', error);
    res.status(500).json({ error: error.message });
  }
});

// ---------------------------------------------------------------------------
// PATCH /api/orders/:id/status (Update Order Status)
// ---------------------------------------------------------------------------
router.patch('/:id/status', async (req: Request<{ id: string }, {}, UpdateOrderStatusBody>, res: Response) => {
  try {
    const orderId = parseInt(req.params.id, 10);
    const { status } = req.body;

    if (isNaN(orderId)) {
      return res.status(400).json({ error: 'Invalid order ID.' });
    }

    if (!Object.values(OrderStatus).includes(status)) {
      return res.status(400).json({
        error: `Invalid status. Must be one of: ${Object.values(OrderStatus).join(', ')}`,
      });
    }

    const updatedOrder = await prisma.order.update({
      where: { id: orderId },
      data: { status },
    });

    res.json(updatedOrder);
  } catch (error: any) {
    console.error('Error updating order status:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;