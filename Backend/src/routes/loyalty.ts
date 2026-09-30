import { Router, Request, Response } from 'express';
import { prisma } from '../config/prisma.js';
import { authGuard } from '../middleware/authGuard.js';
import { roleGuard } from '../middleware/roleGuard.js';
import {
  getBalance,
  redeemVoucher,
  InsufficientPointsError,
  UnknownTierError,
  REWARD_TIERS,
} from '../services/pointsService.js';

const router = Router();

// Loyalty is a customer feature.
router.use(authGuard, roleGuard('CUSTOMER'));

// ---------------------------------------------------------------------------
// GET /api/loyalty/wallet — points balance + the customer's vouchers
// ---------------------------------------------------------------------------
router.get('/wallet', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const [balance, vouchers, ledger] = await Promise.all([
      getBalance(userId),
      prisma.voucher.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.pointsTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ]);

    return res.json({
      balance,
      tiers: REWARD_TIERS,
      vouchers: vouchers.map((v) => ({
        id: v.id,
        amountOff: v.amountOff,
        used: v.used,
        createdAt: v.createdAt,
        usedAt: v.usedAt,
      })),
      recentTransactions: ledger.map((t) => ({
        id: t.id,
        delta: t.delta,
        reason: t.reason,
        orderId: t.orderId,
        createdAt: t.createdAt,
      })),
    });
  } catch (error: unknown) {
    console.error('Error loading wallet:', error);
    return res.status(500).json({ error: 'Failed to load wallet.' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/loyalty/tiers — the predetermined reward catalog
// ---------------------------------------------------------------------------
router.get('/tiers', async (_req: Request, res: Response) => {
  return res.json({ tiers: REWARD_TIERS });
});

// ---------------------------------------------------------------------------
// POST /api/loyalty/redeem — redeem a chosen tier for a voucher (atomic).
// Body: { tierId: string }
// ---------------------------------------------------------------------------
router.post('/redeem', async (req: Request, res: Response) => {
  try {
    const tierId = (req.body ?? {}).tierId;
    if (typeof tierId !== 'string' || tierId.trim().length === 0) {
      return res.status(400).json({ error: 'tierId is required.' });
    }
    const { voucherId } = await redeemVoucher(req.user!.id, tierId);
    const balance = await getBalance(req.user!.id);
    return res.status(201).json({ voucherId, balance });
  } catch (error: unknown) {
    if (error instanceof InsufficientPointsError || error instanceof UnknownTierError) {
      return res.status(400).json({ error: error.message });
    }
    console.error('Error redeeming voucher:', error);
    return res.status(500).json({ error: 'Failed to redeem voucher.' });
  }
});

export default router;
