/**
 * Loyalty points & vouchers (Requirement 15).
 *
 * Points are a ledger: every award/redeem is a PointsTransaction row with a
 * signed delta, and the balance is the sum of those deltas (never a mutable
 * counter, so it can't drift). Earning rule:
 *
 *   points = floor(amountPaid / 10_000) * 5
 *
 * computed on the amount actually paid (finalTotal, i.e. after any voucher).
 * Redeeming 100 points yields one single-use Rp 10.000 voucher.
 */

import { Prisma, OrderStatus, PaymentStatus } from '@prisma/client';
import type { PrismaClient } from '@prisma/client';
import { prisma as defaultPrisma } from '../config/prisma.js';

type Db = PrismaClient | Prisma.TransactionClient;

export const POINTS_PER_10K = 5;

/**
 * Predetermined reward catalog (no admin). Higher tiers give a better
 * rupiah-per-point rate to reward saving. `amountOff` is the voucher value.
 */
export interface RewardTier {
  id: string;
  points: number;
  amountOff: number;
}

export const REWARD_TIERS: RewardTier[] = [
  { id: 'small', points: 50, amountOff: 5000 },
  { id: 'medium', points: 100, amountOff: 12000 },
  { id: 'large', points: 250, amountOff: 35000 },
];

export function getRewardTier(id: string): RewardTier | undefined {
  return REWARD_TIERS.find((t) => t.id === id);
}

/** Points earned for a given paid amount (whole rupiah). */
export function pointsForAmount(amountPaid: number): number {
  if (!Number.isFinite(amountPaid) || amountPaid <= 0) return 0;
  return Math.floor(amountPaid / 10000) * POINTS_PER_10K;
}

/** Current points balance = sum of the user's ledger deltas. */
export async function getBalance(userId: number, db: Db = defaultPrisma): Promise<number> {
  const agg = await db.pointsTransaction.aggregate({
    where: { userId },
    _sum: { delta: true },
  });
  return agg._sum.delta ?? 0;
}

/**
 * Award points for a completed+settled order, once. Idempotent: if a
 * ORDER_COMPLETED ledger entry already exists for this order, does nothing.
 * Returns the number of points awarded (0 if none / already awarded).
 */
export async function awardPointsForOrder(
  orderId: number,
  db: Db = defaultPrisma
): Promise<number> {
  const order = await db.order.findUnique({
    where: { id: orderId },
    include: { payments: true },
  });
  if (!order) return 0;
  if (order.status !== OrderStatus.COMPLETED) return 0;

  const settled = order.payments.some((p) => p.status === PaymentStatus.SETTLED);
  if (!settled) return 0;

  // Idempotency guard.
  const existing = await db.pointsTransaction.findFirst({
    where: { orderId, reason: 'ORDER_COMPLETED' },
  });
  if (existing) return 0;

  const amountPaid = order.finalTotal ?? 0;
  const points = pointsForAmount(amountPaid);
  if (points <= 0) return 0;

  await db.pointsTransaction.create({
    data: { userId: order.customerId, delta: points, reason: 'ORDER_COMPLETED', orderId },
  });
  return points;
}

export class InsufficientPointsError extends Error {
  constructor() {
    super('Not enough points to redeem.');
    this.name = 'InsufficientPointsError';
  }
}

export class UnknownTierError extends Error {
  constructor() {
    super('Unknown reward tier.');
    this.name = 'UnknownTierError';
  }
}

/**
 * Redeem a reward tier: deduct the tier's point cost and create a single-use
 * voucher for the tier's value, atomically. Throws UnknownTierError for a bad
 * tier id, or InsufficientPointsError if the balance is too low.
 */
export async function redeemVoucher(
  userId: number,
  tierId: string
): Promise<{ voucherId: number }> {
  const tier = getRewardTier(tierId);
  if (!tier) {
    throw new UnknownTierError();
  }
  return defaultPrisma.$transaction(async (tx) => {
    const balance = await getBalance(userId, tx);
    if (balance < tier.points) {
      throw new InsufficientPointsError();
    }
    await tx.pointsTransaction.create({
      data: { userId, delta: -tier.points, reason: 'VOUCHER_REDEEM' },
    });
    const voucher = await tx.voucher.create({
      data: { userId, amountOff: tier.amountOff, used: false },
    });
    return { voucherId: voucher.id };
  });
}
