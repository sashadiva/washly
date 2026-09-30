/**
 * Midtrans Snap integration (Requirement 8).
 *
 * We call the Snap REST API directly with the Server Key (Basic auth) rather
 * than pulling in the midtrans-client SDK, keeping dependencies minimal. In
 * sandbox mode we target app.sandbox.midtrans.com; production would use
 * app.midtrans.com. The server key never leaves the backend.
 *
 * The webhook signature is verified with the documented formula:
 *   sha512(order_id + status_code + gross_amount + ServerKey)
 */

import crypto from 'crypto';

function isProduction(): boolean {
  return String(process.env.MIDTRANS_IS_PRODUCTION).toLowerCase() === 'true';
}

function serverKey(): string {
  const key = process.env.MIDTRANS_SERVER_KEY;
  if (!key || key.length === 0) {
    throw new Error('MIDTRANS_SERVER_KEY is not configured');
  }
  return key;
}

function snapBaseUrl(): string {
  return isProduction()
    ? 'https://app.midtrans.com/snap/v1/transactions'
    : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
}

export interface SnapCustomer {
  first_name?: string;
  email?: string;
  phone?: string;
}

export interface CreateSnapParams {
  /** Our unique reference sent to Midtrans (must be unique per attempt). */
  orderId: string;
  /** Whole-rupiah gross amount. */
  grossAmount: number;
  customer?: SnapCustomer;
}

export interface SnapResult {
  token: string;
  redirectUrl: string;
}

/**
 * Create a Snap transaction and return the token + redirect URL.
 * Throws with the Midtrans error text on non-2xx.
 */
export async function createSnapTransaction(
  params: CreateSnapParams
): Promise<SnapResult> {
  const auth = Buffer.from(`${serverKey()}:`).toString('base64');

  const body = {
    transaction_details: {
      order_id: params.orderId,
      gross_amount: Math.round(params.grossAmount),
    },
    credit_card: { secure: true },
    customer_details: params.customer ?? {},
  };

  const resp = await fetch(snapBaseUrl(), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Authorization: `Basic ${auth}`,
    },
    body: JSON.stringify(body),
  });

  const data = (await resp.json().catch(() => ({}))) as {
    token?: string;
    redirect_url?: string;
    error_messages?: string[];
    status_message?: string;
  };

  if (!resp.ok || !data.token) {
    const msg =
      data.error_messages?.join('; ') ||
      data.status_message ||
      `Midtrans returned ${resp.status}`;
    throw new Error(`Failed to create Snap transaction: ${msg}`);
  }

  return { token: data.token, redirectUrl: data.redirect_url ?? '' };
}

export interface MidtransNotification {
  order_id?: string;
  status_code?: string;
  gross_amount?: string;
  signature_key?: string;
  transaction_status?: string;
  fraud_status?: string;
  payment_type?: string;
  [key: string]: unknown;
}

/**
 * Verify the notification signature:
 *   sha512(order_id + status_code + gross_amount + ServerKey)
 * Uses a timing-safe comparison. Returns false if any field is missing.
 */
export function verifyNotificationSignature(n: MidtransNotification): boolean {
  const { order_id, status_code, gross_amount, signature_key } = n;
  if (!order_id || !status_code || !gross_amount || !signature_key) {
    return false;
  }
  const expected = crypto
    .createHash('sha512')
    .update(`${order_id}${status_code}${gross_amount}${serverKey()}`)
    .digest('hex');

  const a = Buffer.from(expected);
  const b = Buffer.from(signature_key);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export type SettlementOutcome = 'SETTLED' | 'PENDING' | 'FAILED' | 'EXPIRED' | 'CANCELLED';

/**
 * Map a Midtrans transaction_status (+ fraud_status) to our PaymentStatus.
 * settlement/capture(accept) -> SETTLED; pending -> PENDING;
 * deny/failure -> FAILED; expire -> EXPIRED; cancel -> CANCELLED.
 */
export function mapTransactionStatus(n: MidtransNotification): SettlementOutcome {
  const status = (n.transaction_status ?? '').toLowerCase();
  const fraud = (n.fraud_status ?? '').toLowerCase();

  switch (status) {
    case 'capture':
      // For card payments, capture is only good when fraud check accepts.
      return fraud === 'deny' || fraud === 'challenge' ? 'FAILED' : 'SETTLED';
    case 'settlement':
      return 'SETTLED';
    case 'pending':
      return 'PENDING';
    case 'deny':
    case 'failure':
      return 'FAILED';
    case 'expire':
      return 'EXPIRED';
    case 'cancel':
      return 'CANCELLED';
    default:
      return 'PENDING';
  }
}
