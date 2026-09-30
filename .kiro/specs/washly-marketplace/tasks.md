# Implementation Plan

Tasks are grouped by the six build phases from the design. Each phase ends with a light verification step (1–2 checks) per the testing strategy. Complete tasks top-to-bottom; later phases depend on earlier ones. All new screens reuse `Frontend/lib/theme/app_theme.dart`.

## Overview

This plan implements the Washly three-role marketplace (Customer, Partner, Driver) across six phases: authentication & roles, data-model/shared-rule expansion, customer core, partner core, driver core, Midtrans payments, and loyalty/warranty. Each phase builds on the previous one and ends with a light verification step. All frontend work reuses the existing blue theme in `Frontend/lib/theme/app_theme.dart`.

## Tasks

## Phase 0 – Authentication & role foundations

- [x] 1. Extend the data model for auth and roles
  - Add `DRIVER` to the `Role` enum and create the `DriverProfile` model in `Backend/prisma/schema.prisma`
  - Create the migration and regenerate the Prisma client
  - _Requirements: 1.4_

- [x] 2. Build backend auth services and middleware
  - [x] 2.1 Add `passwordService.ts` (bcrypt hash/compare) and `tokenService.ts` (JWT sign/verify with `JWT_SECRET`, `JWT_EXPIRES_IN`)
    - _Requirements: 1.6, 2.1_
  - [x] 2.2 Add `authGuard.ts` (verify Bearer JWT, attach `req.user`) and `roleGuard.ts` (assert role in allowed set)
    - _Requirements: 2.4, 2.5_

- [x] 3. Implement auth routes
  - [x] 3.1 `POST /api/auth/register` — role-branched; create User (+ Laundromat for PARTNER, + DriverProfile for DRIVER) in a transaction; reject duplicate email; validate role-specific required fields
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.7_
  - [x] 3.2 `POST /api/auth/login` (return `{token, user}`, generic error on failure) and `GET /api/auth/me`
    - _Requirements: 2.1, 2.2, 2.7_
  - [x] 3.3 Register the auth router in `app.ts`
    - _Requirements: 2.1_

- [x] 4. Frontend auth foundation
  - [x] 4.1 Add `shared_preferences` and `provider` to `pubspec.yaml`; create `auth_store.dart` (persist/read token + current user) and `auth_service.dart` (register/login/me)
    - _Requirements: 2.1, 2.3_
  - [x] 4.2 Add a Dio interceptor in `api_client.dart` that attaches the Bearer token and clears session + routes to login on 401
    - _Requirements: 2.4_
  - [x] 4.3 Build `RoleSelect`, `Login`, and role-specific registration screens (customer/partner/driver) using existing theme
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [x] 4.4 Implement app-start session routing in `session.dart`/`main.dart` (valid token -> role home; else login) and logout
    - _Requirements: 2.3, 2.6, 2.7_

- [x] 5. Account settings (all roles)
  - [x] 5.1 Backend `PUT /api/account/profile` (name, phone; email immutable) and `PUT /api/account/password` (validate current, hash new)
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.7_
  - [x] 5.2 Shared `AccountSettingsScreen` (edit name/phone, change password, logout; email read-only) placed under each role's Profile tab
    - _Requirements: 17.1, 17.4, 17.6_

- [x] 6. Phase 0 verification
  - Backend smoke test: register a customer, partner, and driver; login each; confirm token role routes correctly; confirm duplicate email is rejected and password change requires the correct current password
  - Manual: register + login each role in Chrome and land on the correct (placeholder) home
  - _Requirements: 1.5, 2.1, 2.2, 17.4_

## Phase 1 – Data model expansion & shared rules

- [x] 7. Expand order-related schema
  - [x] 7.1 Extend `OrderStatus` (11 states), add `PaymentStatus`, `DriverAvailability`, `OfferStatus`, `WarrantyClaimStatus` enums
    - _Requirements: 5.5, 6.1, 8.6, 13.1, 16.7_
  - [x] 7.2 Add/extend models: `Order` (items, pricing snapshot, fee, weighedKg, finalTotal, voucher, driver), `OrderItem`, `DeliveryOffer`, `Payment`, `PointsTransaction`, `Voucher`, `DeclaredItem`, `WarrantyClaim`; migrate and regenerate client
    - _Requirements: 5.1, 8.6, 13.1, 15.1, 16.1_

- [x] 8. Shared rule services
  - [x] 8.1 Extract haversine into `distanceService.ts`; add `deliveryFeeService.ts` implementing 5.000 base + ceil(km-5)*1.000
    - _Requirements: 5.2_
  - [x] 8.2 Add `orderStateMachine.ts` (allowed transitions + per-role guards; illegal -> 409)
    - _Requirements: 6.1, 6.3_
  - [x] 8.3 Add `toCustomerLaundromat` response mapper that omits exact address/lat/lng and returns distance + areaLabel; add `areaLabel` to `Laundromat`
    - _Requirements: 3.4, 3.5, 11.3_

- [x] 9. Update discovery/detail to hide location
  - Apply `toCustomerLaundromat` to `GET /api/laundromats` and `GET /api/laundromats/:id`; keep tag filter + sort; return list without distance if customer coords absent
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

- [x] 10. Update dev seed
  - Seed one customer, two partners (with services + `areaLabel` + coords), two drivers, and marketplace tags so all roles are demoable
  - _Requirements: 1.2, 1.3, 1.4_

- [x] 11. Phase 1 verification
  - Unit: `deliveryFeeService` (e.g. 4km=5000, 5km=5000, 7km=7000, 8.3km=9000 per the design formula) and one illegal state-machine transition rejected
  - API check: customer discovery response contains no address/lat/lng
  - _Requirements: 3.4, 5.2, 6.3_
  - NOTE: tasks.md originally listed "8.3km=8000", which contradicts the design formula `5000 + ceil(distance-5)*1000` (ceil(3.3)=4 -> 9000). Implemented/tested per the authoritative formula (9000). Confirm with the team if 8000 was intended.

## Phase 2 – Customer core (ordering, tracking, history, receipts)

- [x] 12. Rich order model on the frontend
  - Add Dart models: rich `Order` (items, status, fee, weighed, totals), `OrderItem`, and update `CartItem` usage; add `order_service.dart`
  - _Requirements: 5.1, 6.1, 9.2_

- [x] 13. Order creation endpoint
  - `POST /api/orders`: build `OrderItem`s from cart, compute distance + delivery fee, set `pricingModel` snapshot; per-item compute `itemsSubtotal`/`finalTotal`, per-kg estimate only; set initial status `PENDING_ACCEPTANCE`; accept optional `declaredItems` and `voucherId`; validate non-empty cart + pickup address
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 16.1_

- [x] 14. Extend checkout screen
  - Replace hardcoded `customerId: 1` with the authed user and the hardcoded fee with the server-computed fee; per-kg checkout shows "final price after weighing" instead of a total; add optional declared-item capture (`image_picker`) and voucher selection placeholder (wired in Phase 6)
  - _Requirements: 4.2, 4.3, 5.2, 5.4, 16.1, 16.2_

- [x] 15. Order tracking and history
  - [x] 15.1 Backend `GET /api/orders/mine` and `GET /api/orders/:id` (owner-scoped, includes items + timeline + receipt fields)
    - _Requirements: 6.1, 6.2, 9.1, 9.2, 9.3_
  - [x] 15.2 Customer Orders tab: active tracking with a `StatusTimeline` widget (discrete stages, no map) and past-order history list
    - _Requirements: 6.1, 6.2, 6.4, 9.1_
  - [x] 15.3 Receipt view (line items, weights/qty, delivery fee, voucher, points earned, payment status, grand total)
    - _Requirements: 9.2_

- [x] 16. Per-kg weigh-in confirmation (customer side)
  - Backend `POST /api/orders/:id/approve-weight` (customer-only; WEIGHED_AWAITING_CONFIRM -> AWAITING_PAYMENT); UI to view measured weight + final price and approve
  - _Requirements: 7.2, 7.3_

- [x] 17. Phase 2 verification
  - API: create a per-item order and a per-kg order; confirm fee computed, per-item has total, per-kg has estimate only; confirm `GET /orders/mine` returns only the caller's orders
  - Manual: place an order in Chrome and see it in the Orders tab
  - _Requirements: 5.2, 5.3, 5.4, 9.3_
  - VERIFIED: API checks pass (per-item fee 9000/subtotal/final + lineTotals; per-kg fee 5000, subtotal/final/lineTotal null; /mine owner-scoped; cross-customer detail -> 404). `flutter build web` compiles the full app. Interactive Chrome click-through left for a human (cannot drive a browser in this environment).

## Phase 3 – Partner core (order management, profile/services, dashboard)

- [x] 18. Partner order management endpoints
  - [x] 18.1 `GET /api/partner/orders` (own laundromat only); `accept`/`reject` (reject -> CANCELLED; accept requires per-item payment SETTLED)
    - _Requirements: 10.1, 10.2, 10.5_
  - [x] 18.2 `POST /api/partner/orders/:id/weigh` (per-kg: set `weighedKg`, compute final price -> WEIGHED_AWAITING_CONFIRM) and `POST .../ready` (WASHING -> READY_FOR_DELIVERY)
    - _Requirements: 7.1, 10.3, 10.4_

- [x] 19. Partner profile and services endpoints
  - `GET/PUT /api/partner/profile` (description, image, specialties, pricing model, coords, areaLabel; own only); `GET/POST/PUT/DELETE /api/partner/services[/:id]`
  - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [x] 20. Partner sales dashboard endpoint
  - `GET /api/partner/dashboard?from=&to=` computing revenue + order counts from own paid orders; zeros when none
  - _Requirements: 12.1, 12.2, 12.3_

- [x] 21. Partner screens
  - Build `partner_service.dart` and screens: Dashboard (summary), Orders (accept/reject, weigh-in entry, advance status), Services editor, Profile (shop editor + account settings), all on existing theme
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 11.1, 11.2, 12.1_

- [x] 22. Phase 3 verification
  - API: partner accepts an order and advances status; partner A cannot see/act on partner B's orders; dashboard sums only own paid orders
  - Manual: partner logs in, views incoming order, enters weight for a per-kg order
  - _Requirements: 10.5, 12.2_
  - VERIFIED: paid per-item accept -> ACCEPTED; partner B cannot see/reject A's order (404); dashboard A revenue=55000/paid=1 vs B=0. `flutter build web` compiles. Also fixed the review-dialog hardcoded `userId: 1` (now uses AuthStore) and its async-gap lint; full `dart analyze` clean. Interactive Chrome click-through left for a human.

## Phase 4 – Driver core (assignment, accept/reject, status, history)

- [x] 23. Assignment engine
  - `assignmentService.ts`: on `ACCEPTED` (pickup) and `READY_FOR_DELIVERY` (delivery), offer to nearest AVAILABLE driver via `DeliveryOffer`; accept assigns + sets driver BUSY + expires siblings; reject re-offers next nearest; exhausted list leaves order awaiting
  - _Requirements: 13.1, 13.2, 13.3, 13.5_

- [x] 24. Driver endpoints
  - `GET /api/driver/offers`; `accept`/`reject`; `POST .../picked-up` (DRIVER_ASSIGNED -> PICKED_UP); `POST .../delivered` (OUT_FOR_DELIVERY -> COMPLETED, trigger completion effects); `PUT /api/driver/availability` (Active/Not Active + location); `GET /api/driver/history`
  - _Requirements: 13.2, 13.3, 13.4, 14.1, 14.2, 14.3, 14.4_

- [x] 25. Driver screens
  - Build `driver_service.dart` and screens: Offers (accept/reject), Active delivery (mark picked-up/delivered), History, Profile (account settings + Active/Not Active availability toggle, labeled to avoid internet-connectivity confusion)
  - _Requirements: 13.4, 14.1, 14.3_

- [x] 26. Phase 4 verification
  - API: an accepted order is offered to the nearest available driver; reject re-offers to the next; accept assigns and stops further offers; driver sees only own offers/history
  - Manual: driver accepts an offer and marks it delivered -> order shows COMPLETED
  - _Requirements: 13.2, 13.3, 14.1, 14.4_
  - VERIFIED: full lifecycle exercised live — accept offers to nearest (Andi) not far driver; reject re-offers to next (Budi); accept assigns + BUSY + expires siblings + no open offers; cross-driver action -> 404; picked-up -> PICKED_UP; delivery offered to available driver; delivered -> COMPLETED + driver freed; history owner-scoped. `flutter build web` compiles. Interactive Chrome click-through left for a human.

## Phase 5 – Payments (Midtrans Sandbox)

- [x] 27. Midtrans service and payment creation
  - `midtransService.ts` (create Snap transaction with server key; helper to verify notification signature); `POST /api/payments/:orderId/create` returns `snapToken`; record `Payment` (PENDING); add env vars `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, `MIDTRANS_IS_PRODUCTION=false`, `APP_WEBHOOK_BASE_URL`
  - _Requirements: 8.1, 8.6_

- [x] 28. Webhook (source of truth)
  - `POST /api/payments/webhook`: verify signature; map settlement/capture -> SETTLED (else FAILED/EXPIRED/CANCELLED); update `Payment` + `Order`; advance state machine when the required charge is satisfied; idempotent; document ngrok tunnel usage in `.env`
  - _Requirements: 8.3, 8.4, 8.5_

- [x] 29. Frontend payment launcher
  - `PaymentLauncher` abstraction + `payment_service.dart`: open Snap (redirect on web / SDK-or-webview on mobile) using the token; poll order status after return
  - _Requirements: 8.2_

- [x] 30. Wire payment into both moments
  - Per-item: pay at checkout before partner acceptance; per-kg: pay after weigh-in approval (AWAITING_PAYMENT); on SETTLED advance to WASHING
  - _Requirements: 5.3, 7.3, 7.4, 8.4_

- [x] 31. Phase 5 verification
  - API: webhook with a valid signature marks the order paid and advances state; an invalid signature does not; a client cannot mark an order paid directly
  - Manual: complete a sandbox payment via Snap in Chrome and see the order advance
  - _Requirements: 8.3, 8.4, 8.5_
  - VERIFIED (API): real Snap create returned a token (sandbox keys valid); valid-signature webhook -> SETTLED + order unblocked; invalid signature -> 403 no change; duplicate webhook idempotent; no client endpoint can mark paid. `flutter build web` compiles. MANUAL (needs user's machine): run `ngrok http 5000`, set APP_WEBHOOK_BASE_URL + Midtrans dashboard Payment Notification URL to `<ngrok>/api/payments/webhook`, then complete a Snap payment in Chrome and watch the order advance.

## Phase 6 – Loyalty & warranty

- [x] 32. Loyalty backend
  - `pointsService.ts`: award floor(amountPaid/10000)*5 on COMPLETED+SETTLED (ledger entry); balance = sum of ledger; `POST /api/loyalty/redeem` (100 points -> Rp 10.000 voucher, atomic); `GET /api/loyalty/wallet`; apply voucher at checkout (reduce payable before Midtrans, mark voucher used, single-use)
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_

- [x] 33. Home hub with wallet (customer)
  - Build Home tab: `HeroBanner` (bundled asset + gradient fallback, greeting), active-order status card, discovery search entry, specialty shortcuts (pre-filtered discovery), loyalty wallet (balance + redeem vouchers), reorder shortcut; add hero asset to `assets/` + `pubspec.yaml`; set customer nav to Home | Discovery | Orders | Profile
  - _Requirements: 15.6, 18.1, 18.2, 18.3, 18.4, 18.5, 18.6, 18.7, 18.8_
  - NOTE: HeroBanner uses the gradient fallback path (always renders) with an `errorBuilder` for a missing asset; no binary image committed. Drop a JPG at `Frontend/assets/hero_banner.jpg` + declare in pubspec later if a photo is wanted.

- [x] 34. Warranty backend
  - Declared items captured at order creation (Task 13); `POST /api/partner/orders/:id/intake` (confirm declared items received or flag discrepancy); `POST /api/orders/:id/claims` (only against declared+confirmed items on a completed order, owner-only); `GET /api/orders/:id/claims`; `POST /api/partner/claims/:id/resolve` (partner-only; status + note; payout attributed to Washly)
  - _Requirements: 16.3, 16.4, 16.5, 16.6, 16.7, 16.8, 16.9, 16.10_

- [x] 35. Warranty screens
  - Partner intake-confirm action in order detail; customer warranty-claim submission from a completed order (description + photos) and claim status view; partner claim review/resolve
  - _Requirements: 16.3, 16.5, 16.9_

- [x] 36. Phase 6 verification
  - API: completing a paid order awards correct points; redeeming 100 points yields a single-use Rp 10.000 voucher and applying it reduces payable; a claim is rejected unless its item was declared + partner-confirmed
  - Manual: view points on Home after an order; submit a warranty claim on a declared item
  - _Requirements: 15.1, 15.4, 16.6_
  - VERIFIED (API): completed paid order awarded 35 pts for Rp 75.000; redeem gated <100 (400) then yielded a voucher; voucher reduced payable 40000->30000 and is single-use; claim rejected unless item declared+partner-confirmed. `flutter build web` compiles the full app; 16 backend unit tests pass. Interactive Chrome click-through left for a human.


## Task Dependency Graph

- Phase 0 (Tasks 1–6) — foundation; nothing precedes it.
- Phase 1 (Tasks 7–11) — depends on Phase 0 (needs auth/roles + migrations).
- Phase 2 (Tasks 12–17) — depends on Phase 1 (order schema, fee/state-machine, discovery).
- Phase 3 (Tasks 18–22) — depends on Phase 2 (orders must exist to manage).
- Phase 4 (Tasks 23–26) — depends on Phase 3 (partner acceptance triggers pickup offers) and the state machine from Phase 1.
- Phase 5 (Tasks 27–31) — depends on Phase 2 (orders) and Phase 3 (per-item acceptance requires payment); wires into per-kg confirm from Phase 2.
- Phase 6 (Tasks 32–36) — depends on Phase 5 (points award on settled/completed; voucher reduces payable) and Phase 2 (declared items captured at order creation).

Within a phase, subtasks are ordered; backend endpoints generally precede the screens that consume them.

```json
{
  "waves": [
    { "wave": 1, "tasks": ["1", "2", "3", "4", "5", "6"], "dependsOn": [] },
    { "wave": 2, "tasks": ["7", "8", "9", "10", "11"], "dependsOn": [1] },
    { "wave": 3, "tasks": ["12", "13", "14", "15", "16", "17"], "dependsOn": [2] },
    { "wave": 4, "tasks": ["18", "19", "20", "21", "22"], "dependsOn": [3] },
    { "wave": 5, "tasks": ["23", "24", "25", "26"], "dependsOn": [4] },
    { "wave": 6, "tasks": ["27", "28", "29", "30", "31"], "dependsOn": [3] },
    { "wave": 7, "tasks": ["32", "33", "34", "35", "36"], "dependsOn": [5, 6] }
  ]
}
```


## Notes

- Verification is intentionally light per the requirements: 1–2 checks per feature (endpoint smoke tests + a couple of pure-function unit tests, plus manual click-through in Chrome). No exhaustive suites.
- The dev database is disposable; migrations that supersede the old `Order.serviceType/estimatedKg/totalPrice` fields reset seed data.
- Midtrans runs in Sandbox; the webhook requires a tunnel (ngrok) in local dev, documented in `Backend/.env`.
- All money is whole rupiah; all new screens consume existing theme tokens only.
