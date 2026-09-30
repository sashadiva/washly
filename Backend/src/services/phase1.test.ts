/**
 * Phase 1 verification (light, per the testing strategy).
 *
 * Run with:  npm run test
 * Uses the built-in Node test runner via tsx (no extra dependencies).
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { feeFor } from './deliveryFeeService.js';
import { nextStatus, IllegalTransitionError } from './orderStateMachine.js';

// --- Delivery fee correctness (Requirement 5.2) --------------------------

test('deliveryFee: 4km is base 5000 (within first 5km)', () => {
  assert.equal(feeFor(4), 5000);
});

test('deliveryFee: 5km is exactly base 5000 (boundary inclusive)', () => {
  assert.equal(feeFor(5), 5000);
});

test('deliveryFee: 7km is 7000 (5000 + 2 extra km)', () => {
  assert.equal(feeFor(7), 7000);
});

test('deliveryFee: 8.3km rounds extra UP to 9000 (5000 + ceil(3.3)=4 * 1000)', () => {
  // NOTE: tasks.md lists "8.3km=8000" as the example, but that contradicts the
  // authoritative formula in design.md (5000 + ceil(distance-5)*1000), which
  // gives ceil(3.3)=4 -> 9000. The formula and its "round extra UP" wording are
  // the source of truth, so we assert 9000. (Flagged to the team.)
  assert.equal(feeFor(8.3), 9000);
});

test('deliveryFee is non-decreasing in distance', () => {
  let prev = -1;
  for (let km = 0; km <= 30; km += 0.5) {
    const fee = feeFor(km);
    assert.ok(fee >= prev, `fee should not decrease at ${km}km`);
    prev = fee;
  }
});

// --- State-machine legality (Requirement 6.3) ----------------------------

test('stateMachine: legal transition returns next status', () => {
  // Partner accepting a pending order is allowed.
  assert.equal(nextStatus('accept', 'PENDING_ACCEPTANCE', 'PARTNER'), 'ACCEPTED');
});

test('stateMachine: illegal transition is rejected', () => {
  // A driver cannot "accept" an order, and you cannot deliver a pending order.
  assert.throws(
    () => nextStatus('markDelivered', 'PENDING_ACCEPTANCE', 'DRIVER'),
    IllegalTransitionError
  );
});

test('stateMachine: wrong role is rejected even from a valid source state', () => {
  // Only the partner may accept; a customer attempting it is rejected.
  assert.throws(
    () => nextStatus('accept', 'PENDING_ACCEPTANCE', 'CUSTOMER'),
    IllegalTransitionError
  );
});
