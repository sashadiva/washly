/**
 * Delivery fee rule (Requirement 5.2).
 *
 *   base fee            = Rp 5.000 for the first 5 km (inclusive)
 *   each extra whole km = Rp 1.000, rounding the extra distance UP
 *
 * Formula:
 *   distance <= 5  ->  5000
 *   distance  > 5  ->  5000 + ceil(distance - 5) * 1000
 *
 * The fee is non-decreasing in distance. Money is whole rupiah.
 */

const BASE_FEE = 5000;
const BASE_DISTANCE_KM = 5;
const PER_EXTRA_KM = 1000;

export function feeFor(distanceKm: number): number {
  if (!Number.isFinite(distanceKm) || distanceKm <= BASE_DISTANCE_KM) {
    return BASE_FEE;
  }
  const extraKm = Math.ceil(distanceKm - BASE_DISTANCE_KM);
  return BASE_FEE + extraKm * PER_EXTRA_KM;
}
