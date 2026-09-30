/**
 * Midtrans service unit tests (signature verification + status mapping).
 * Run with:  npm run test
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';

import {
  verifyNotificationSignature,
  mapTransactionStatus,
} from './midtransService.js';

// The service reads MIDTRANS_SERVER_KEY at call time; set a known value.
const TEST_KEY = 'test-server-key';
process.env.MIDTRANS_SERVER_KEY = TEST_KEY;

function sign(orderId: string, statusCode: string, grossAmount: string): string {
  return crypto
    .createHash('sha512')
    .update(`${orderId}${statusCode}${grossAmount}${TEST_KEY}`)
    .digest('hex');
}

test('signature: a correctly-signed notification is accepted', () => {
  const n = {
    order_id: 'WASHLY-1-123',
    status_code: '200',
    gross_amount: '30000.00',
  };
  const signature_key = sign(n.order_id, n.status_code, n.gross_amount);
  assert.equal(verifyNotificationSignature({ ...n, signature_key }), true);
});

test('signature: a tampered amount is rejected', () => {
  const n = {
    order_id: 'WASHLY-1-123',
    status_code: '200',
    gross_amount: '30000.00',
  };
  const signature_key = sign(n.order_id, n.status_code, n.gross_amount);
  // Attacker inflates the amount but keeps the old signature.
  assert.equal(
    verifyNotificationSignature({ ...n, gross_amount: '1.00', signature_key }),
    false
  );
});

test('signature: a missing signature is rejected', () => {
  assert.equal(
    verifyNotificationSignature({
      order_id: 'x',
      status_code: '200',
      gross_amount: '1.00',
    }),
    false
  );
});

test('status: settlement maps to SETTLED', () => {
  assert.equal(mapTransactionStatus({ transaction_status: 'settlement' }), 'SETTLED');
});

test('status: capture+accept maps to SETTLED, capture+deny to FAILED', () => {
  assert.equal(
    mapTransactionStatus({ transaction_status: 'capture', fraud_status: 'accept' }),
    'SETTLED'
  );
  assert.equal(
    mapTransactionStatus({ transaction_status: 'capture', fraud_status: 'deny' }),
    'FAILED'
  );
});

test('status: expire/cancel/deny map correctly', () => {
  assert.equal(mapTransactionStatus({ transaction_status: 'expire' }), 'EXPIRED');
  assert.equal(mapTransactionStatus({ transaction_status: 'cancel' }), 'CANCELLED');
  assert.equal(mapTransactionStatus({ transaction_status: 'deny' }), 'FAILED');
  assert.equal(mapTransactionStatus({ transaction_status: 'pending' }), 'PENDING');
});
