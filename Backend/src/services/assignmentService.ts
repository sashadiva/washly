/**
 * Driver assignment engine (Requirement 13).
 *
 * When an order becomes ready for a driver leg, we offer it to the nearest
 * AVAILABLE driver via a DeliveryOffer. The driver polls their offers and
 * accepts/rejects; accepting assigns them and expires sibling offers; rejecting
 * re-offers to the next nearest driver. If no drivers are available the order
 * simply waits — a later availability change can trigger re-offering.
 *
 * Two phases share one mechanism:
 *   PICKUP   — triggered when the partner accepts (order ACCEPTED). The driver
 *              drives to the CUSTOMER to collect the dirty laundry, then takes
 *              it to the laundromat, so "nearest" is measured to the customer.
 *   DELIVERY — triggered when the partner marks ready (READY_FOR_DELIVERY). The
 *              driver collects the washed laundry at the laundromat, so
 *              "nearest" is measured to the laundromat.
 */

import { OfferStatus, DriverAvailability, Prisma } from '@prisma/client';
import type { PrismaClient } from '@prisma/client';
import { prisma as defaultPrisma } from '../config/prisma.js';
import { getDistanceKm } from './distanceService.js';

export type OfferPhase = 'PICKUP' | 'DELIVERY';

type Db = PrismaClient | Prisma.TransactionClient;

/**
 * Offer the order to the nearest AVAILABLE driver who has not already been
 * offered this order in this phase and has not rejected/expired it. Creates a
 * single OFFERED DeliveryOffer, or does nothing if no eligible driver exists.
 *
 * Returns the created offer, or null when nobody is available.
 */
export async function offerToNearestDriver(
  orderId: number,
  phase: OfferPhase,
  db: Db = defaultPrisma
): Promise<{ id: number; driverId: number } | null> {
  const order = await db.order.findUnique({
    where: { id: orderId },
    include: { laundromat: true },
  });
  if (!order) return null;

  // PICKUP: driver goes to the customer first, so rank by distance to the
  // customer (falling back to the laundromat if the customer has no coords).
  // DELIVERY: driver collects the washed laundry at the laundromat.
  const useCustomer =
    phase === 'PICKUP' && order.customerLat != null && order.customerLng != null;
  const refLat = useCustomer ? order.customerLat! : order.laundromat.latitude;
  const refLng = useCustomer ? order.customerLng! : order.laundromat.longitude;

  // Drivers who already have an offer for this order+phase that is OFFERED or
  // ACCEPTED must not be offered again. (REJECTED/EXPIRED can't re-receive
  // either, per "not-yet-offered".)
  const priorOffers = await db.deliveryOffer.findMany({
    where: { orderId, phase },
    select: { driverId: true },
  });
  const excludedDriverIds = new Set(priorOffers.map((o) => o.driverId));

  const availableDrivers = await db.driverProfile.findMany({
    where: { availability: DriverAvailability.AVAILABLE },
  });

  const candidates = availableDrivers
    .filter((d) => !excludedDriverIds.has(d.id))
    .map((d) => ({
      driver: d,
      distance:
        d.latitude != null && d.longitude != null
          ? getDistanceKm(d.latitude, d.longitude, refLat, refLng)
          : Number.POSITIVE_INFINITY,
    }))
    .sort((a, b) => a.distance - b.distance);

  const nearest = candidates[0];
  if (!nearest) return null;

  const offer = await db.deliveryOffer.create({
    data: {
      orderId,
      driverId: nearest.driver.id,
      phase,
      status: OfferStatus.OFFERED,
    },
    select: { id: true, driverId: true },
  });
  return offer;
}

/**
 * Re-offer after a driver rejects: the current offer is already marked REJECTED
 * by the caller; this finds the next nearest eligible driver.
 */
export async function reofferToNextDriver(
  orderId: number,
  phase: OfferPhase,
  db: Db = defaultPrisma
): Promise<{ id: number; driverId: number } | null> {
  return offerToNearestDriver(orderId, phase, db);
}
