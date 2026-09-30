/**
 * Location secrecy mapper (Requirements 3.4, 3.5, 11.3).
 *
 * Customer-facing responses must NEVER include a laundromat's exact street
 * address or raw latitude/longitude. `toCustomerLaundromat` returns only the
 * safe-to-expose fields plus a server-computed `distanceKm` and a coarse
 * `areaLabel` (e.g. district). Raw coordinates stay server-side and are used
 * only to compute distance.
 */

import { getDistanceKm } from './distanceService.js';

/** The private laundromat shape (superset of what we expose). */
export interface LaundromatLike {
  id: number;
  name: string;
  areaLabel: string | null;
  latitude: number;
  longitude: number;
  imageUrl: string | null;
  rating: number;
  reviewCount: number;
  // Optional extras that some responses include (e.g. detail view).
  description?: string | null;
  tags?: string[];
  services?: unknown[];
  reviews?: unknown[];
}

/** The customer-safe laundromat shape. Note: no address, no lat/lng. */
export interface CustomerLaundromat {
  id: number;
  name: string;
  areaLabel: string | null;
  imageUrl: string | null;
  rating: number;
  reviewCount: number;
  distanceKm: number | null;
  description?: string | null;
  tags?: string[];
  services?: unknown[];
  reviews?: unknown[];
}

/**
 * Maps a laundromat to its customer-facing shape.
 *
 * @param shop        the private laundromat record (must include lat/lng)
 * @param customerLat optional customer latitude for distance
 * @param customerLng optional customer longitude for distance
 *
 * When customer coords are absent, `distanceKm` is null (list can still render;
 * distance sorting simply won't apply). Distance is rounded to 1 decimal.
 */
export function toCustomerLaundromat(
  shop: LaundromatLike,
  customerLat?: number | null,
  customerLng?: number | null
): CustomerLaundromat {
  let distanceKm: number | null = null;

  if (
    customerLat != null &&
    customerLng != null &&
    Number.isFinite(customerLat) &&
    Number.isFinite(customerLng)
  ) {
    const raw = getDistanceKm(customerLat, customerLng, shop.latitude, shop.longitude);
    distanceKm = parseFloat(raw.toFixed(1));
  }

  const mapped: CustomerLaundromat = {
    id: shop.id,
    name: shop.name,
    areaLabel: shop.areaLabel ?? null,
    imageUrl: shop.imageUrl ?? null,
    rating: shop.rating,
    reviewCount: shop.reviewCount,
    distanceKm,
  };

  // Pass through optional detail fields when present, still omitting location.
  if ('description' in shop) mapped.description = shop.description ?? null;
  if (shop.tags) mapped.tags = shop.tags;
  if (shop.services) mapped.services = shop.services;
  if (shop.reviews) mapped.reviews = shop.reviews;

  return mapped;
}
