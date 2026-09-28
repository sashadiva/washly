# Design Document

## Overview

This design expands Washly from a single-user customer prototype into a three-role laundry marketplace (Customer, Partner, Driver) on the existing stack: **Flutter** (web/mobile) frontend, **Node/Express + TypeScript** backend, **Prisma 7 + PostgreSQL**, running under **Docker Compose** locally. It adds JWT authentication and role routing, a multi-role order lifecycle, Midtrans Sandbox payments, loyalty points/vouchers, and a declared-item warranty system.

The design deliberately **extends existing structures** rather than replacing them:
- The current `Laundromat` model already serves as the partner profile; the current `Order`, `LaundryService`, `Review`, and `Tag` models are reused and extended.
- The Flutter theme in `Frontend/lib/theme/app_theme.dart` (Washly blue `#1E88E5`, spacing/radius/typography tokens) is the single source of visual truth for all new screens. No new color system is introduced.
- The existing Dio-based `ApiClient` is extended with an auth interceptor rather than rewritten.

### Design goals and non-goals
- **Goals:** correct multi-role flows, secure auth, a real (sandbox) payment round-trip, and a demoable end-to-end experience consistent with the existing UI.
- **Non-goals (prototype scope):** production hardening, real courier integration (driver role is first-party and simulated for movement), a real financial ledger (warranty payout is an attribution, not a treasury), push notifications, and exhaustive automated testing (1–2 checks per feature per the requirements).

### Requirements coverage map
- R1, R2 -> Authentication & Authorization
- R3, R4 -> Discovery & Catalog (location hiding)
- R5, R6, R7 -> Order Lifecycle & State Machine
- R8 -> Payments (Midtrans)
- R9 -> History & Receipts
- R10, R11, R12 -> Partner services
- R13, R14 -> Driver services & assignment engine
- R15 -> Loyalty (points/vouchers)
- R16 -> Declared-item warranty

## Architecture

### High-level component view

```
Flutter App (one codebase, role-routed)
 ├─ Customer shell   ├─ Partner shell   ├─ Driver shell
 └─ Shared: ApiClient (Dio + JWT interceptor), models, theme, auth store

            │  HTTPS/JSON (Bearer JWT)
            ▼
Express API (src/)
 ├─ routes/        auth, laundromats, orders, partner, driver, payments, loyalty, warranty
 ├─ middleware/    authGuard (JWT verify), roleGuard(role[])
 ├─ services/      order state machine, delivery fee, distance, assignment, points, midtrans
 └─ config/        prisma client, env
            │
            ▼
PostgreSQL (Prisma 7)      ◄── Midtrans webhook ── Midtrans Sandbox
```

### Backend structural changes
The backend currently has `src/app.ts`, `src/config/prisma.ts`, and two route files. This grows into a conventional layered layout while keeping the existing files:

```
Backend/src/
  app.ts                     # add cors (done), route registration, webhook raw body
  config/prisma.ts           # unchanged
  middleware/
    authGuard.ts             # verifies JWT, attaches req.user {id, role}
    roleGuard.ts             # asserts req.user.role in allowed set
  services/
    tokenService.ts          # sign/verify JWT
    passwordService.ts       # bcrypt hash/compare
    distanceService.ts       # haversine (extracted from laundromat.ts)
    deliveryFeeService.ts    # fee formula
    orderStateMachine.ts     # allowed transitions + guards
    assignmentService.ts     # nearest-available-driver offer/re-offer
    pointsService.ts         # award/redeem
    midtransService.ts       # create transaction, verify notification signature
  routes/
    auth.ts                  # register (role-branched), login, me
    laundromat.ts            # discovery/detail (extended: hide location)
    order.ts                 # customer order create/list/track (extended)
    partner.ts               # partner orders, profile, services, dashboard, intake
    driver.ts                # offers, accept/reject, deliver, history
    payment.ts               # create payment, midtrans webhook
    loyalty.ts               # wallet, redeem
    warranty.ts              # declare (via order), confirm intake, claim, resolve
```

### Frontend structural changes
```
Frontend/lib/
  core/
    api_client.dart          # + JWT interceptor, + auth error handling
    auth_store.dart          # token persistence (shared_preferences), current user/role
    session.dart             # app-start routing based on stored token
  models/                    # + auth, order (rich), payment, points, voucher, warranty, driver
  services/                  # + auth_service, order_service, partner_service, driver_service,
                             #   payment_service, loyalty_service, warranty_service
  screens/
    auth/                    # role_select, login, register_customer/partner/driver
    customer/                # home (hub: hero, active order, shortcuts, wallet, reorder),
                             #   discovery (existing), detail (existing), checkout (existing),
                             #   tracking, history, receipt, warranty_claim
    account/                 # shared account_settings (name/phone/password/logout), all roles
    partner/                 # dashboard, orders, order_detail(intake/weigh/advance),
                             #   profile_edit, services_edit, claims
    driver/                  # offers, active_delivery, history
  theme/app_theme.dart       # unchanged (source of visual truth)
  (assets/)                  # bundled hero banner image, declared in pubspec.yaml
  widgets/                   # shared: status_timeline, primary_button wrappers, etc.
```

New Flutter packages (added to `pubspec.yaml`):
- `shared_preferences` — persist JWT.
- `provider` (or `flutter_riverpod`) — lightweight auth/session state. Provider chosen for simplicity and small footprint.
- `midtrans_sdk` or a `webview_flutter`-based Snap integration — open the Snap payment page. On Flutter **web**, Snap is opened via redirect/JS; on mobile via the SDK/webview. Design keeps a `PaymentLauncher` abstraction so the platform difference is isolated.
- `image_picker` — capture declared-item and claim photos.

## Data Models

The Prisma schema is extended. Existing models (`User`, `Laundromat`, `LaundryService`, `Tag`, `LaundromatsOnTags`, `Review`, `Order`) are kept; new fields and models are added. Enums are extended.

### Enum changes

```prisma
enum Role {
  CUSTOMER
  PARTNER
  DRIVER          // added
}

enum OrderStatus {
  PENDING_ACCEPTANCE          // created, waiting for partner (replaces implicit PICKUP_REQUESTED entry)
  ACCEPTED                    // partner accepted, ready to offer to a driver
  DRIVER_ASSIGNED             // a driver accepted the pickup offer
  PICKED_UP                   // driver collected laundry
  WEIGHED_AWAITING_CONFIRM    // per-kg only: partner weighed, awaiting customer approval
  AWAITING_PAYMENT            // payment required (per-item: at start; per-kg: after confirm)
  WASHING                     // payment confirmed, in service
  READY_FOR_DELIVERY          // washing done, ready to offer delivery
  OUT_FOR_DELIVERY            // driver delivering
  COMPLETED                   // delivered
  CANCELLED                   // rejected or aborted
}

enum PricingUnit {            // unchanged
  PER_KG
  PER_ITEM
}

enum PaymentStatus {          // new
  PENDING
  SETTLED
  FAILED
  EXPIRED
  CANCELLED
}

enum DriverAvailability {     // new
  AVAILABLE
  BUSY
  OFFLINE
}

enum OfferStatus {            // new
  OFFERED
  ACCEPTED
  REJECTED
  EXPIRED
}

enum WarrantyClaimStatus {    // new
  SUBMITTED
  APPROVED
  REJECTED
  RESOLVED
}
```

### New and extended models

```prisma
// User: passwordHash already exists; role extended. No structural change beyond role enum.

model DriverProfile {
  id           Int                @id @default(autoincrement())
  userId       Int                @unique
  user         User               @relation(fields: [userId], references: [id], onDelete: Cascade)
  vehicleType  String
  plateNumber  String
  availability DriverAvailability @default(OFFLINE)
  latitude     Float?             // last known location for nearest-driver matching
  longitude    Float?
  createdAt    DateTime           @default(now())
  updatedAt    DateTime           @updatedAt

  offers       DeliveryOffer[]
  assignedOrders Order[]          @relation("DriverOrders")
}

// Order: extended with items, pricing split, driver, fee, weight.
model Order {
  id                Int          @id @default(autoincrement())
  status            OrderStatus  @default(PENDING_ACCEPTANCE)
  pricingModel      PricingUnit                              // snapshot of the shop's model at order time
  pickupAddress     String
  deliveryAddress   String
  customerLat       Float?                                   // used for fee + distance
  customerLng       Float?
  notes             String?

  distanceKm        Float?                                   // computed at creation
  deliveryFee       Float                                     // computed via deliveryFeeService
  itemsSubtotal     Float?                                   // per-item known at checkout; per-kg null until weighed
  weighedKg         Float?                                   // per-kg only, set at weigh-in
  finalTotal        Float?                                   // subtotal(+weighed) + fee - voucher
  voucherDiscount   Float        @default(0)

  createdAt         DateTime     @default(now())
  updatedAt         DateTime     @updatedAt

  customerId        Int
  customer          User         @relation("CustomerOrders", fields: [customerId], references: [id])
  laundromatId      Int
  laundromat        Laundromat   @relation(fields: [laundromatId], references: [id])
  driverId          Int?
  driver            DriverProfile? @relation("DriverOrders", fields: [driverId], references: [id])

  items             OrderItem[]
  offers            DeliveryOffer[]
  payments          Payment[]
  declaredItems     DeclaredItem[]
  warrantyClaims    WarrantyClaim[]
  appliedVoucherId  Int?         @unique
  appliedVoucher    Voucher?     @relation(fields: [appliedVoucherId], references: [id])
}

model OrderItem {
  id           Int        @id @default(autoincrement())
  orderId      Int
  order        Order      @relation(fields: [orderId], references: [id], onDelete: Cascade)
  serviceId    Int
  serviceName  String                                       // snapshot for receipt stability
  unit         PricingUnit
  unitPrice    Float                                        // snapshot
  quantity     Float                                        // pieces (per-item) or estimated kg (per-kg)
  lineTotal    Float?                                       // null for per-kg until weighed
  notes        String?
}

model DeliveryOffer {
  id           Int          @id @default(autoincrement())
  orderId      Int
  order        Order        @relation(fields: [orderId], references: [id], onDelete: Cascade)
  driverId     Int
  driver       DriverProfile @relation(fields: [driverId], references: [id], onDelete: Cascade)
  phase        String                                       // "PICKUP" or "DELIVERY"
  status       OfferStatus  @default(OFFERED)
  createdAt    DateTime     @default(now())
  respondedAt  DateTime?

  @@index([driverId, status])
}

model Payment {
  id            Int           @id @default(autoincrement())
  orderId       Int
  order         Order         @relation(fields: [orderId], references: [id], onDelete: Cascade)
  amount        Float
  method        String?                                     // filled from Midtrans notification
  status        PaymentStatus @default(PENDING)
  midtransOrderId String      @unique                       // our reference sent to Midtrans
  snapToken     String?
  rawNotification Json?
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt
}

model PointsTransaction {
  id          Int       @id @default(autoincrement())
  userId      Int
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  delta       Int                                            // +earned, -redeemed
  reason      String                                         // "ORDER_COMPLETED", "VOUCHER_REDEEM"
  orderId     Int?
  createdAt   DateTime  @default(now())
}

model Voucher {
  id          Int       @id @default(autoincrement())
  userId      Int
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  amountOff   Float     @default(10000)
  used        Boolean   @default(false)
  createdAt   DateTime  @default(now())
  usedAt      DateTime?
  order       Order?    @relation
}

model DeclaredItem {
  id          Int      @id @default(autoincrement())
  orderId     Int
  order       Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)
  label       String
  photoUrl    String
  confirmedReceived Boolean @default(false)                  // set true at partner intake
  discrepancyNote   String?
  createdAt   DateTime @default(now())

  claims      WarrantyClaim[]
}

model WarrantyClaim {
  id            Int                 @id @default(autoincrement())
  orderId       Int
  order         Order               @relation(fields: [orderId], references: [id], onDelete: Cascade)
  declaredItemId Int
  declaredItem  DeclaredItem        @relation(fields: [declaredItemId], references: [id], onDelete: Cascade)
  description   String
  photoUrls     String[]
  status        WarrantyClaimStatus @default(SUBMITTED)
  resolutionNote String?
  payoutAmount  Float?                                       // attributed to Washly (platform), informational
  payoutFundedBy String?           @default("WASHLY")
  createdAt     DateTime            @default(now())
  updatedAt     DateTime            @updatedAt
}
```

Notes on modeling choices:
- **Snapshots** (`serviceName`, `unitPrice`, `pricingModel`) are copied onto orders/items so receipts stay stable even if a partner later edits services or prices. This directly supports R9 (receipts) and R12 (dashboard integrity).
- **`User` points balance** is derived by summing `PointsTransaction.delta` (a ledger, not a mutable counter) so the wallet in R15 is auditable and cannot drift.
- **`DeliveryOffer.phase`** lets one model serve both the pickup offer (R13) and the delivery offer (after washing), avoiding two near-identical tables.
- Existing `Order.serviceType`/`estimatedKg`/`totalPrice` fields are superseded by `OrderItem` + `finalTotal`/`weighedKg`. A migration maps/drops them; existing seed data is reset (dev DB is disposable).

## Order Lifecycle State Machine

The lifecycle differs by pricing model at exactly one branch (payment timing). `orderStateMachine.ts` centralizes allowed transitions and the role permitted to trigger each; routes call it rather than mutating `status` directly.

```
                 ┌────────────────────── per-item ──────────────────────┐
CREATE ──▶ PENDING_ACCEPTANCE ──partner accept──▶ ACCEPTED
   │  (per-item: AWAITING_PAYMENT first, see note)      │
   │                                                    │ offer pickup to nearest driver
   ▼ partner reject                                     ▼ driver accepts
CANCELLED                                          DRIVER_ASSIGNED
                                                        │ driver marks picked up
                                                        ▼
                                                    PICKED_UP
                            ┌──────────── per-kg ───────────┤ per-item
                            ▼                                ▼
                   WEIGHED_AWAITING_CONFIRM             WASHING
                            │ customer approves            │ (already paid at checkout)
                            ▼                              │
                     AWAITING_PAYMENT ──paid──▶ WASHING ◀─┘
                                                        │ partner marks ready
                                                        ▼
                                                 READY_FOR_DELIVERY
                                                        │ offer delivery to nearest driver, driver accepts + delivers
                                                        ▼
                                                 OUT_FOR_DELIVERY
                                                        │ driver marks delivered
                                                        ▼
                                                   COMPLETED ──▶ award points, finalize receipt, open warranty window
```

Payment-timing note:
- **Per-item:** payment happens up front. At creation the order goes `PENDING_ACCEPTANCE` with a `Payment` created immediately; only after `SETTLED` (webhook) does the partner see it as acceptable. To keep the diagram simple: per-item requires paid-then-accept; per-kg requires accept-pickup-weigh-confirm-pay. Implementation: the state machine exposes `canPartnerAccept(order)` which requires payment SETTLED for per-item.
- **Per-kg:** no upfront charge; the single `AWAITING_PAYMENT` state after weigh-in confirmation handles the charge.

Transition guards (examples enforced by the state machine + roleGuard):
- Only the order's **partner** may `accept`, `reject`, `enterWeight`, `markReady`.
- Only the assigned **driver** may `markPickedUp`, `markDelivered`.
- Only the order's **customer** may `approveWeight`, `applyVoucher`, `pay`, `fileClaim`.
- Illegal transitions return HTTP 409 with the current state.

## Components and Interfaces

### API Design

All endpoints are JSON. Protected routes require `Authorization: Bearer <jwt>` and are gated by `roleGuard`. Money is integer rupiah (float in Prisma but treated as whole rupiah).

### Auth (public)
- `POST /api/auth/register` — body includes `role` and role-specific fields; branches to create User + profile in a transaction. (R1)
- `POST /api/auth/login` — returns `{ token, user: { id, name, role } }`. (R2)
- `GET  /api/auth/me` — returns current user from JWT. (R2.7)

### Account (all roles)
- `PUT /api/account/profile` — update own name and phone (email immutable). (R17.1, R17.2, R17.3)
- `PUT /api/account/password` — body `{ currentPassword, newPassword }`; validates current, stores hashed new. (R17.4, R17.5)

### Discovery & catalog (customer)
- `GET /api/laundromats?tags=&sort=&userLat=&userLng=` — list; response **omits address/lat/lng**, includes `distanceKm` and `areaLabel`. (R3)
- `GET /api/laundromats/:id` — detail with services + reviews; **no exact address/coords**. (R3.4, R4.1)

### Orders (customer)
- `POST /api/orders` — create from cart; computes distance + delivery fee; per-item creates a Payment (AWAITING/PENDING), per-kg estimate only. Accepts optional `declaredItems` and `voucherId`. (R5, R16.1)
- `GET  /api/orders/mine` — customer's orders (list + status). (R6, R9.1)
- `GET  /api/orders/:id` — full order + items + timeline + receipt fields (owner only). (R6, R9.2)
- `POST /api/orders/:id/approve-weight` — customer approves weighed price -> AWAITING_PAYMENT. (R7.2, R7.3)

### Payments (customer + webhook)
- `POST /api/payments/:orderId/create` — backend creates Midtrans transaction, returns `snapToken`/redirect. (R8.1)
- `POST /api/payments/webhook` — Midtrans notification; verifies signature; updates Payment + Order; triggers points on completion path. **Source of truth.** Public but signature-verified. (R8.3–R8.5)

### Partner
- `GET   /api/partner/orders` — orders for the partner's laundromat. (R10.1)
- `POST  /api/partner/orders/:id/accept` | `/reject`. (R10.2)
- `POST  /api/partner/orders/:id/intake` — confirm declared items received (or flag discrepancy). (R16.3, R16.4)
- `POST  /api/partner/orders/:id/weigh` — body `{ weighedKg }`; computes final price -> WEIGHED_AWAITING_CONFIRM. (R7.1, R10.3)
- `POST  /api/partner/orders/:id/ready` — WASHING -> READY_FOR_DELIVERY. (R10.4)
- `GET   /api/partner/profile` / `PUT /api/partner/profile` — edit laundromat. (R11.1, R11.3)
- `GET/POST/PUT/DELETE /api/partner/services[/:id]` — manage services. (R11.2)
- `GET   /api/partner/dashboard?from=&to=` — revenue + counts from own paid orders. (R12)
- `GET   /api/partner/claims` / `POST /api/partner/claims/:id/resolve` — review/resolve warranty. (R16.8)

### Driver
- `GET  /api/driver/offers` — orders currently OFFERED to this driver. (R13.4)
- `POST /api/driver/offers/:id/accept` | `/reject` — accept assigns; reject re-offers next nearest. (R13.2, R13.3)
- `POST /api/driver/orders/:id/picked-up` — DRIVER_ASSIGNED -> PICKED_UP. (state machine)
- `POST /api/driver/orders/:id/delivered` — OUT_FOR_DELIVERY -> COMPLETED. (R14.1, R14.2)
- `PUT  /api/driver/availability` — set AVAILABLE/OFFLINE + location. (R13 matching)
- `GET  /api/driver/history` — completed deliveries. (R14.3)

### Loyalty (customer)
- `GET  /api/loyalty/wallet` — points balance (sum of ledger) + available vouchers. (R15.6)
- `POST /api/loyalty/redeem` — 100 points -> Rp 10.000 voucher. (R15.2)

### Warranty (customer)
- `POST /api/orders/:id/claims` — file claim against a declared+confirmed item on a completed order. (R16.5, R16.6)
- `GET  /api/orders/:id/claims` — customer views claim status/resolution. (R16.9)

## Key Mechanisms

### Delivery fee (deliveryFeeService)
```
feeFor(distanceKm):
  if distanceKm <= 5: return 5000
  extra = ceil(distanceKm - 5)          # round extra distance up to whole km
  return 5000 + extra * 1000
```
Computed once at order creation from customer coords + laundromat coords (haversine, extracted from the existing `laundromat.ts` implementation into `distanceService.ts`). (R5.2)

### Location hiding (R3.4, R11.3)
The laundromat coordinates and street address are **never serialized** into any customer-facing response. A response mapper (`toCustomerLaundromat`) returns only `{ id, name, imageUrl, rating, reviewCount, tags, distanceKm, areaLabel }`. `areaLabel` is a coarse descriptor (e.g. district) stored on the laundromat, separate from the exact address the partner sees. Distance is computed server-side; raw coords stay server-side.

### Driver assignment (assignmentService) (R13)
1. On `ACCEPTED` (pickup) or `READY_FOR_DELIVERY` (delivery), gather drivers with `availability = AVAILABLE`, ordered by haversine distance to the pickup point.
2. Create a `DeliveryOffer` (OFFERED) for the nearest not-yet-offered driver.
3. Accept -> mark offer ACCEPTED, set `order.driverId`, transition order, set driver BUSY, expire sibling offers.
4. Reject (or timeout, checked lazily on next poll) -> mark REJECTED, offer the next nearest.
5. If the list is exhausted -> order stays in its awaiting state; a later availability change re-triggers offering. (R13.5)
Polling model (no websockets in prototype): the driver app polls `GET /api/driver/offers`; the customer/partner apps poll order status. Simple and sufficient for a demo.

### Payments with Midtrans (midtransService) (R8)
- Backend uses `MIDTRANS_SERVER_KEY` (env only) to call Snap `POST /transactions`, storing `midtransOrderId` and `snapToken` on a `Payment`.
- App opens Snap with the token (`PaymentLauncher` abstraction: webview/SDK on mobile, redirect on web).
- Midtrans -> `POST /api/payments/webhook`: verify `signature_key = sha512(order_id + status_code + gross_amount + ServerKey)`; map `settlement/capture` -> SETTLED, else FAILED/EXPIRED/CANCELLED; update Payment + Order; if this payment completes the order's required charge, advance the state machine.
- **Local webhook reachability:** Midtrans must reach `localhost:5000`. Dev uses a tunnel (ngrok) whose URL is set in the Midtrans dashboard; `.env` documents this. The webhook is idempotent (safe to receive duplicates).

### Points & vouchers (pointsService) (R15)
- On order COMPLETED with a SETTLED payment: `points = floor(amountPaid / 10000) * 5`, insert a `PointsTransaction(+points)`.
- Balance = sum of the user's `PointsTransaction.delta`.
- Redeem: if balance >= 100, insert `PointsTransaction(-100)` and create a `Voucher(amountOff=10000)` atomically.
- Applying a voucher at checkout sets `order.voucherDiscount=10000`, marks the voucher used, and the payable (and thus Midtrans gross_amount) is reduced before the transaction is created. Points are computed on the reduced amount actually paid. (R15.3, R15.5)

## Frontend Design

### Session & routing
`main.dart` wraps the app in an auth `Provider`. On start, `session.dart` reads the stored JWT (`shared_preferences`); if valid, routes to the role home, else to `RoleSelect`/`Login`. `ApiClient` gains a Dio interceptor that attaches the Bearer token and, on 401, clears the token and returns to login. (R2.3, R2.4, R2.7)

### Role shells (bottom navigation per role)
- **Customer:** **Home** | Discovery | Orders (tracking + history) | Profile. (R18.1)
- **Partner:** Dashboard | Orders | Services | Profile.
- **Driver:** Offers | Active | History | Profile.
Each shell uses the same `AppColors.primary` blue, `AppBarTheme`, and button/input themes already defined. New shared widgets (e.g. `StatusTimeline`, `DeclaredItemCard`, `MoneyText`, `HeroBanner`, `SpecialtyShortcut`) live in `lib/widgets/` and consume existing `AppTypography`/`AppSpacing` tokens.

### Customer Home hub (R18)
Home is the customer's landing tab and summary hub, composed of (top to bottom):
- **Hero banner** (`HeroBanner` widget): renders a bundled image asset from `Frontend/assets/` (declared in `pubspec.yaml`); IF the asset is missing it falls back to a branded gradient using `AppColors.primary` -> `AppColors.primaryDark` with the app name overlay, so it always renders. Greeting ("Hi, {name}") overlays the banner. (R18.2)
- **Active-order status card**: shows the current in-progress order's status with a tap-through to tracking; neutral empty state when none. (R18.3)
- **Discovery entry**: a search field / "Find laundry" action routing to Discovery. (R18.4)
- **Specialty shortcuts**: chips/tiles that open Discovery pre-filtered by tag. (R18.5)
- **Loyalty wallet**: points balance + available vouchers with redeem action. The full wallet lives here on Home (not under Profile). (R18.6, R15.6)
- **Reorder shortcut**: starts a new order from a prior order. (R18.7)
Home composes data already provided by discovery, orders, and loyalty endpoints; no new backend endpoints are required beyond those.

### Profile / Account settings (all roles) (R17)
A shared `AccountSettingsScreen` under each role's Profile tab: edit name and phone, change password (requires current password), and log out. Email is shown read-only. Backend: `GET /api/auth/me`, `PUT /api/account/profile` (name, phone), `PUT /api/account/password` (currentPassword, newPassword). Partner Profile additionally hosts the shop profile editor (R11); Driver Profile additionally hosts the **Active / Not Active** availability toggle (labeled to avoid implying internet connectivity), which calls `PUT /api/driver/availability`.

### Reused existing screens
- `DiscoveryScreen`, `LaundromatDetailScreen`, `CheckoutScreen` are kept and extended: checkout gains voucher selection and optional declared-item capture (`image_picker`), and switches the hardcoded `customerId: 1` and hardcoded delivery fee to the authed user + server-computed fee. The per-kg checkout no longer shows a final total (shows "final price after weighing").

### Consistency rules
- No new colors, radii, or font sizes beyond `app_theme.dart`. Status chips map lifecycle states to existing tokens (`success` for completed, `error` for cancelled, `primary` for in-progress, `ratingStar`/`textMuted` for pending).
- Money always rendered "Rp {value}" via a shared `MoneyText` widget.

## Correctness Properties

These invariants are what the light tests target.

### Property 1: Auth isolation
Every list/detail endpoint returns only records owned by the authenticated user: a customer sees only their own orders, claims, and wallet; a partner only their own laundromat orders, services, and claims; a driver only their own offers and history. (R2.5, R9.3, R10.5, R11.4, R14.4, R16.10)

**Validates: Requirements 2.5, 9.3, 10.5, 11.4, 14.4, 16.10**

### Property 2: Location secrecy
No customer-facing response ever contains a laundromat exact street address or raw latitude/longitude; only distance and a coarse area label are exposed. (R3.4)

**Validates: Requirements 3.4**

### Property 3: Delivery fee correctness
The delivery fee is exactly Rp 5.000 for distance <= 5 km, and for greater distance equals 5.000 + ceil(distance - 5) * 1.000; it is non-decreasing in distance. (R5.2)

**Validates: Requirements 5.2**

### Property 4: Payment authority
An order is marked paid only as the result of a signature-valid Midtrans webhook, never by a direct client call; webhook processing is idempotent. (R8.3, R8.4)

**Validates: Requirements 8.3, 8.4**

### Property 5: Points integrity
Points are awarded only for a completed order with a settled payment, computed as floor(amountPaid / 10.000) * 5 on the amount paid after any voucher; the wallet balance always equals the sum of the points ledger; a voucher applies to at most one order. (R15.1, R15.4, R15.5)

**Validates: Requirements 15.1, 15.4, 15.5**

### Property 6: State-machine legality
An order moves only along defined transitions and only when triggered by the role permitted for that transition; illegal transitions are rejected with 409 and do not mutate state. (R5, R6, R7, R10, R13, R14)

**Validates: Requirements 5, 6, 7, 10, 13, 14**

### Property 7: Warranty gating
A warranty claim can be created only against a declared item that the partner confirmed at intake, on a completed order owned by the claimant, and only that order's partner may resolve it. (R16.5, R16.6, R16.10)

**Validates: Requirements 16.5, 16.6, 16.10**

## Error Handling
- Backend: consistent `{ error: string }` shape (matches existing routes). 400 validation, 401 unauthenticated, 403 wrong role, 404 not owned/found, 409 illegal state transition, 500 unexpected. Prisma unique-constraint (e.g. duplicate email) mapped to 400/409 with a clear message.
- Frontend: services throw typed exceptions from Dio errors (existing pattern); screens show `SnackBar`/inline errors using `AppColors.error`. 401 triggers logout+redirect globally.
- Webhook: always returns 200 to Midtrans after processing to avoid ret60ry storms, but only mutates state on valid signature; invalid signature -> log + 403.

## Testing Strategy
Per the requirements, verification is light — 1–2 checks per feature to confirm it works:
- **Backend:** a small set of endpoint smoke tests (supertest) for the critical paths: register/login, order create + fee calc, weigh-in -> confirm, webhook -> SETTLED transition, driver accept assignment, points award, claim gating. Pure functions (`deliveryFeeService`, `pointsService`, `orderStateMachine` guards) get 1–2 unit tests each since they encode the money/rules.
- **Frontend:** 1 widget/smoke test per role shell that it renders and routes; manual click-through in Chrome for full flows (matching current dev workflow).
- No exhaustive coverage, load, or E2E automation in this phase.

## Deployment / Dev Environment
- Continues under Docker Compose (db on host 5433, backend on 5000). New env vars in `Backend/.env`: `JWT_SECRET`, `JWT_EXPIRES_IN`, `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, `MIDTRANS_IS_PRODUCTION=false`, `APP_WEBHOOK_BASE_URL` (the ngrok URL in dev).
- Prisma migrations add the new models/enums; the dev seed is updated to create sample users of each role (a customer, 2 partners with services, 2 drivers) so all three roles are demoable immediately.
- Flutter continues to run in Chrome via `flutter run -d chrome --web-port 8080`.
- A bundled hero image is placed under `Frontend/assets/` and declared in `pubspec.yaml` (`flutter: assets:`). The Home `HeroBanner` renders a branded gradient fallback if the asset is absent, so the build never breaks on a missing file.
