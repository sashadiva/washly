/**
 * Points math unit tests (Requirement 15.1).
 * Run with:  npm run test
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { pointsForAmount } from './pointsService.js';

test('points: floor(amount/10000)*5', () => {
  assert.equal(pointsForAmount(0), 0);
  assert.equal(pointsForAmount(9999), 0); // under 10k earns nothing
  assert.equal(pointsForAmount(10000), 5); // exactly 10k -> 5
  assert.equal(pointsForAmount(25000), 10); // floor(2.5)=2 -> 10
  assert.equal(pointsForAmount(79000), 35); // floor(7.9)=7 -> 35
  assert.equal(pointsForAmount(100000), 50);
});

test('points: non-positive/invalid amounts earn nothing', () => {
  assert.equal(pointsForAmount(-5), 0);
  assert.equal(pointsForAmount(Number.NaN), 0);
});
