/**
 * Shared pricing constants used across order creation and weigh-in so the
 * charged total stays consistent regardless of where it is computed.
 */

// Flat, one-time protection fee applied to an order that carries declared
// items (valuables photographed at checkout for warranty coverage).
export const DECLARED_ITEMS_FEE = 2000;

/** The protection fee for an order, based on whether it has declared items. */
export function declaredItemsFeeFor(hasDeclaredItems: boolean): number {
  return hasDeclaredItems ? DECLARED_ITEMS_FEE : 0;
}
