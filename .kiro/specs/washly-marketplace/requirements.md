# Requirements Document

## Introduction

Washly is a three-sided laundry marketplace mobile application (Flutter + Node/Express + PostgreSQL). Today it is a customer-only prototype with no authentication, a single hardcoded user, and a working laundromat discovery/detail/checkout flow. This spec expands Washly into a full marketplace serving three distinct user roles — **Customer**, **Laundromat Partner**, and **Driver** — with role-based authentication, a complete order lifecycle spanning all three roles, real payments via Midtrans Sandbox, a loyalty points system, and a warranty claim process.

The system supports two laundromat pricing models: **per-item** (priced at checkout) and **per-kilogram** (priced after the laundry is physically weighed at pickup). Delivery is handled by Washly's own driver fleet, with a distance-based delivery fee. The customer never sees a laundromat's exact location — only the distance to it — to discourage off-platform transactions.

### Guiding constraints
- **Design consistency:** All new screens reuse the existing theme in `Frontend/lib/theme/app_theme.dart` (blue-dominant palette, existing spacing, radius, and typography tokens).
- **Testing scope:** Light verification only — 1–2 checks per feature to confirm it works, not exhaustive test suites.
- **Auth mechanism:** JWT tokens stored on the device.
- **Payments:** Midtrans Sandbox (real gateway in test mode). The Midtrans Server Key lives only in the backend; the payment result is confirmed by the Midtrans webhook, which is the source of truth.
- **Delivery fee:** Base Rp 5.000 for distance <= 5 km; for distance > 5 km, add Rp 1.000 per kilometer over 5 km, rounding the extra distance up to the next whole kilometer.
- **Points:** Earn 5 points per Rp 10.000 spent (on confirmed/completed payment). 100 points redeem for a Rp 10.000-off voucher.

### Build phasing (for reference; requirements below are grouped to align)
- Phase 0 – Authentication & role foundations
- Phase 1 – Data model expansion & shared rules (distance, fee, location hiding)
- Phase 2 – Customer core (ordering, tracking, history, receipts)
- Phase 3 – Partner core (order management, profile/services editor, dashboard)
- Phase 4 – Driver core (assignment, accept/reject, status, history)
- Phase 5 – Payments (Midtrans Sandbox)
- Phase 6 – Loyalty & warranty

---

## Requirements

### Requirement 1: Role-based user registration

**User Story:** As a new user, I want to register as a customer, laundromat partner, or driver with the fields appropriate to my role, so that I get an account and profile suited to how I will use Washly.

#### Acceptance Criteria
1. WHEN a user opens registration THEN the system SHALL present a role selection of Customer, Partner, or Driver before showing role-specific fields.
2. WHEN a user registers as a Customer THEN the system SHALL require name, email, phone, password, and password confirmation, and SHALL create a User with role CUSTOMER.
3. WHEN a user registers as a Partner THEN the system SHALL require name, email, phone, password, password confirmation, business name, business address with map coordinates, pricing model (per-item or per-kg), and specialties, and SHALL create a User with role PARTNER together with an associated Laundromat record in a single transaction.
4. WHEN a user registers as a Driver THEN the system SHALL require name, email, phone, password, password confirmation, vehicle type, and plate number, and SHALL create a User with role DRIVER together with an associated DriverProfile record in a single transaction.
8. WHEN a user submits registration for any role THEN the system SHALL require a password and a matching password confirmation, and SHALL reject the registration with a clear error if the two do not match. Password confirmation is validated on the client; the backend stores only the confirmed password (securely hashed).
5. WHEN a user submits a registration with an email that already exists THEN the system SHALL reject the request with a clear error and SHALL NOT create any record.
6. WHEN a user submits a password THEN the system SHALL store only a securely hashed password and SHALL NOT store the plaintext password.
7. IF any required field for the selected role is missing or invalid THEN the system SHALL reject the registration with a field-level validation error and SHALL NOT create any record.

### Requirement 2: Authentication and role-based routing

**User Story:** As a registered user, I want to log in once and land on the home experience for my role, so that I only see the features relevant to me.

#### Acceptance Criteria
1. WHEN a user submits valid email and password THEN the system SHALL return a JWT access token containing the user's id and role.
2. WHEN a user submits invalid credentials THEN the system SHALL reject the login with a generic authentication error that does not reveal whether the email exists.
3. WHEN the app receives a valid token THEN the system SHALL store it on the device and SHALL route the user to the Customer, Partner, or Driver home screen according to the token's role.
4. WHEN the app makes a request to a protected endpoint THEN the system SHALL include the JWT, and the backend SHALL reject requests with a missing, invalid, or expired token.
5. WHEN a protected endpoint receives a token whose role is not permitted for that endpoint THEN the system SHALL reject the request with an authorization error.
6. WHEN a logged-in user chooses to log out THEN the system SHALL remove the stored token and return the user to the login screen.
7. WHEN the app starts and a valid token is already stored THEN the system SHALL route directly to the role home without requiring re-login.

### Requirement 3: Laundromat discovery with hidden exact location

**User Story:** As a customer, I want to search, filter, and sort laundromats and see how far they are, but not their exact location, so that I can choose conveniently while transactions stay on the platform.

#### Acceptance Criteria
1. WHEN a customer opens discovery THEN the system SHALL list open laundromats with name, image, rating, review count, specialty tags, and distance from the customer.
2. WHEN a customer applies specialty tag filters THEN the system SHALL return only laundromats matching the selected tags.
3. WHEN a customer sorts by rating or by distance THEN the system SHALL order results accordingly.
4. WHEN the discovery or detail data is returned to a customer THEN the system SHALL NOT include the laundromat's exact street address or raw latitude/longitude, and SHALL expose only distance and a general area descriptor.
5. WHEN the system computes distance THEN it SHALL calculate it server-side from the customer's coordinates and the laundromat's coordinates.
6. IF the customer has no known location THEN the system SHALL still return the laundromat list without distance rather than failing.

### Requirement 4: Laundromat detail and cart by pricing model

**User Story:** As a customer, I want to view a laundromat's services and build an order that respects whether it prices per item or per kilogram, so that I order correctly for that shop.

#### Acceptance Criteria
1. WHEN a customer opens a laundromat detail THEN the system SHALL show its description, rating, reviews, specialty tags, and list of services with prices and units.
2. WHEN a service is priced per item THEN the system SHALL let the customer choose a quantity and SHALL compute a line total from quantity x unit price.
3. WHEN a service is priced per kilogram THEN the system SHALL let the customer add it as an estimate without a finalized weight, and SHALL clearly indicate the final price is determined after weighing at pickup.
4. WHEN a customer adds services to a cart THEN the system SHALL maintain the cart with line items, quantities/estimates, and per-line notes for a single laundromat.

### Requirement 5: Order placement (per-item and per-kg flows)

**User Story:** As a customer, I want to place an order for pickup and delivery, paying now for per-item orders or paying after weighing for per-kg orders, so that I am charged the correct amount.

#### Acceptance Criteria
1. WHEN a customer places an order THEN the system SHALL record the order with its line items, pickup address, delivery address, customer, laundromat, and computed delivery fee.
2. WHEN the system computes the delivery fee THEN it SHALL charge Rp 5.000 for distance <= 5 km, and for distance > 5 km SHALL charge Rp 5.000 plus Rp 1.000 per kilometer over 5 km, rounding the extra distance up to the next whole kilometer.
3. WHEN a per-item order is placed THEN the system SHALL calculate the full total at checkout and move the order to payment before partner acceptance.
4. WHEN a per-kg order is placed THEN the system SHALL record an estimated total only, place the order into the pending state without upfront payment, and defer final pricing until after weigh-in.
5. WHEN an order is created THEN the system SHALL set its initial status to reflect that it is awaiting partner acceptance.
6. IF the cart is empty or the pickup address is missing THEN the system SHALL reject order placement with a validation error.

### Requirement 6: Order status tracking

**User Story:** As a customer, I want to track my order through clear status stages, so that I know what is happening without needing a live map.

#### Acceptance Criteria
1. WHEN a customer views an active order THEN the system SHALL show its current status as a stage in a defined lifecycle (for example: awaiting acceptance, driver assigned, picked up, weighed/awaiting confirmation for per-kg, washing, out for delivery, completed, cancelled).
2. WHEN an order's status changes anywhere in the system THEN the customer's view SHALL reflect the updated status on next load.
3. WHEN an order is cancelled THEN the system SHALL show the cancelled state and SHALL stop advancing the lifecycle.
4. The system SHALL present status as discrete stages and SHALL NOT require any live-location map.

### Requirement 7: Per-kilogram weigh-in and price confirmation

**User Story:** As a customer with a per-kg order, I want to see the measured weight and final price after pickup and approve it before paying, so that I only pay for the actual weight of my laundry.

#### Acceptance Criteria
1. WHEN a partner enters the measured weight for a picked-up per-kg order THEN the system SHALL compute the final price from the weight and the service's per-kg rate plus the delivery fee, and SHALL move the order to a weighed/awaiting-confirmation state.
2. WHEN a per-kg order is awaiting confirmation THEN the customer SHALL see the measured weight and final price and SHALL be able to approve it.
3. WHEN the customer approves the weighed price THEN the system SHALL move the order to payment.
4. WHEN payment for the weighed order is confirmed THEN the system SHALL advance the order to washing.
5. IF the customer does not approve the weighed price THEN the order SHALL remain awaiting confirmation and SHALL NOT proceed to washing.

### Requirement 8: Payment via Midtrans Sandbox

**User Story:** As a customer, I want to pay securely through Midtrans, so that my payment is processed reliably and my order proceeds only after real confirmation.

#### Acceptance Criteria
1. WHEN a payment is required THEN the backend SHALL create a Midtrans transaction using the server-side key and SHALL return a payment token/redirect to the app, and the server key SHALL never be exposed to the client.
2. WHEN the app receives the payment token THEN it SHALL open the Midtrans Snap payment interface for the customer to complete payment in the sandbox.
3. WHEN Midtrans sends a payment notification to the backend webhook THEN the system SHALL treat the webhook result as the source of truth for payment status and SHALL update the corresponding Payment and Order accordingly.
4. WHEN a payment is confirmed as settled/captured THEN the system SHALL mark the order paid and allow it to proceed in its lifecycle.
5. WHEN a payment fails, expires, or is cancelled THEN the system SHALL NOT mark the order paid and SHALL reflect the unpaid state.
6. The system SHALL record a Payment entry with amount, method, and status for each payment attempt tied to an order.

### Requirement 9: Order history and receipts

**User Story:** As a customer, I want to view my past orders and their receipts, so that I have a record of my transactions.

#### Acceptance Criteria
1. WHEN a customer opens order history THEN the system SHALL list that customer's past orders with laundromat, date, status, and total.
2. WHEN a customer opens a specific past order THEN the system SHALL show a receipt with line items, weights/quantities, delivery fee, any voucher applied, points earned, payment method/status, and grand total.
3. The system SHALL scope order history so a customer sees only their own orders.

### Requirement 10: Partner order management

**User Story:** As a laundromat partner, I want to accept or reject incoming orders and advance their status, so that I control my workload and keep customers informed.

#### Acceptance Criteria
1. WHEN a partner has incoming orders THEN the system SHALL list orders addressed to that partner's laundromat with their current status.
2. WHEN a partner accepts an order THEN the system SHALL advance it toward driver assignment; WHEN a partner rejects an order THEN the system SHALL cancel it.
3. WHEN a per-kg order has been picked up THEN the partner SHALL be able to enter the measured weight, triggering the weighed/awaiting-confirmation flow in Requirement 7.
4. WHEN a partner advances an order's washing/ready status THEN the system SHALL update the order status accordingly.
5. The system SHALL scope partner order management so a partner sees and acts only on their own laundromat's orders.

### Requirement 11: Partner profile and services management

**User Story:** As a laundromat partner, I want to edit my profile, services, prices, specialties, and location, so that customers see accurate offerings while my exact location stays hidden from them.

#### Acceptance Criteria
1. WHEN a partner edits their laundromat profile THEN the system SHALL allow updating description, image, specialties, pricing model, and location coordinates.
2. WHEN a partner manages services THEN the system SHALL allow creating, updating, and removing services with name, description, price, unit, and image.
3. WHEN a partner updates their location coordinates THEN the system SHALL use them for distance calculations but SHALL NOT expose the exact coordinates or street address to customers.
4. The system SHALL scope profile and service management so a partner can modify only their own laundromat.

### Requirement 12: Partner sales dashboard

**User Story:** As a laundromat partner, I want a dashboard summarizing my sales, so that I can understand my business performance.

#### Acceptance Criteria
1. WHEN a partner opens the dashboard THEN the system SHALL show sales summaries derived from that partner's orders, including total revenue and order counts over a period.
2. The system SHALL compute dashboard figures only from the partner's own completed/paid orders.
3. WHEN the partner has no orders THEN the dashboard SHALL show zeroed figures rather than failing.

### Requirement 13: Driver assignment (auto-offer to nearest available driver)

**User Story:** As a driver, I want to be offered nearby orders that I can accept or reject, so that I can take deliveries that suit me while orders still get covered if I decline.

#### Acceptance Criteria
1. WHEN an order is ready for a driver THEN the system SHALL offer it to the nearest available driver.
2. WHEN a driver accepts an offered order THEN the system SHALL assign the order to that driver and SHALL stop offering it to others.
3. WHEN a driver rejects an offered order THEN the system SHALL re-offer it to the next nearest available driver.
4. WHEN a driver views their offers/assignments THEN the system SHALL show only orders offered to or assigned to that driver.
5. IF no available driver accepts THEN the order SHALL remain awaiting driver assignment rather than being lost.

### Requirement 14: Driver delivery status and history

**User Story:** As a driver, I want to update delivery status and view my completed deliveries, so that I can do my job and keep evidence of my work.

#### Acceptance Criteria
1. WHEN a driver has an active out-for-delivery order THEN the system SHALL allow the driver to mark it delivered, advancing the order to completed.
2. WHEN a driver marks an order delivered THEN the system SHALL trigger completion effects (for example points award and receipt finalization) consistent with other requirements.
3. WHEN a driver opens their history THEN the system SHALL list the deliveries that driver completed with date, order reference, and outcome.
4. The system SHALL scope driver history so a driver sees only their own deliveries.

### Requirement 15: Loyalty points and vouchers

**User Story:** As a customer, I want to earn points on my spending and redeem them for a discount, so that I am rewarded for using Washly.

#### Acceptance Criteria
1. WHEN an order's payment is confirmed and the order completes THEN the system SHALL award the customer 5 points per Rp 10.000 of the amount paid and SHALL record the award in a points ledger.
2. WHEN a customer has at least 100 points THEN the system SHALL allow redeeming 100 points for a Rp 10.000-off voucher, deducting the points.
3. WHEN a customer applies a Rp 10.000-off voucher at checkout THEN the system SHALL reduce the payable amount by Rp 10.000 before creating the Midtrans transaction.
4. WHEN a voucher is applied to an order THEN the system SHALL mark the voucher used so it cannot be applied again.
5. WHEN points are awarded THEN the system SHALL base them on the actual amount paid after any voucher discount, and cancelled or unpaid orders SHALL NOT earn points.
6. WHEN a customer views their wallet THEN the system SHALL show current points balance and available vouchers; the wallet SHALL be accessed from the customer Home area (see Requirement 18).

### Requirement 16: Declared-item warranty (declaration, intake confirmation, claim, resolution)

**User Story:** As a customer, I want to optionally declare specific valuable items with a photo when I order, have the laundromat confirm it received them, and file a claim if a declared item is damaged or lost, so that only the items I care about are protected without photographing my whole load.

Notes: Warranty follows a lightweight "declared items" model. The customer declares only select items (not every piece of laundry). The partner confirms receipt of those declared items in a single step at intake. A claim can only be raised against a declared, partner-confirmed item. The partner reviews and resolves claims, but any payout is funded by Washly (the platform), not the partner.

#### Acceptance Criteria
1. WHEN a customer places an order THEN the system SHALL allow the customer to optionally declare one or more specific items for warranty coverage, each with a photo and a short label/note.
2. IF a customer declares no items on an order THEN that order SHALL have no per-item warranty coverage, and the system SHALL make this clear to the customer at checkout.
3. WHEN a partner receives a picked-up order at intake THEN the system SHALL show the customer's declared items and SHALL allow the partner to either confirm receipt of the declared items in a single action, or flag a discrepancy with an optional note/photo.
4. WHEN a partner confirms the declared items THEN the system SHALL mark those items as confirmed-received, establishing the warranty baseline for the order.
5. WHEN a customer opens a completed order THEN the system SHALL allow submitting a warranty claim only against items that were declared and partner-confirmed on that order, with a description and supporting photo(s).
6. IF an order has no declared, partner-confirmed items THEN the system SHALL NOT allow a warranty claim on that order.
7. WHEN a claim is submitted THEN the system SHALL record it against the order and the specific declared item(s) with an initial status of submitted.
8. WHEN the partner for that order reviews a claim THEN the system SHALL allow the partner to advance its status (for example approved, rejected, or resolved) with a resolution note; the recorded payout amount for an approved claim SHALL be attributed to Washly as the funding party, not the partner.
9. WHEN a customer views a claim THEN the system SHALL show its current status, any resolution note, and any payout outcome.

### Requirement 17: Account settings (all roles)

**User Story:** As any user, I want to edit my account details and change my password, so that I can keep my information current and secure.

#### Acceptance Criteria
1. WHEN any authenticated user opens account settings THEN the system SHALL allow editing their name and phone.
2. WHEN a user updates their name or phone with valid values THEN the system SHALL persist the change and reflect it on next load.
3. The system SHALL display the user's email as read-only and SHALL NOT allow changing it, because email is the login identity.
4. WHEN a user changes their password THEN the system SHALL require the current password, validate it, and store only a securely hashed new password.
5. IF the current password is incorrect OR the new password is invalid THEN the system SHALL reject the change with a clear error and SHALL NOT modify the stored password.
6. WHEN a user chooses to log out from account settings THEN the system SHALL remove the stored token and return the user to the login screen.
7. The system SHALL allow a user to edit only their own account.

### Requirement 18: Customer home hub

**User Story:** As a customer, I want a home screen that greets me and summarizes my activity with quick shortcuts, so that I have a convenient starting point each time I open the app.

#### Acceptance Criteria
1. WHEN a customer opens the app THEN the customer SHALL land on a Home tab that is the first tab in the customer navigation (Home, Discovery, Orders, Profile).
2. WHEN Home loads THEN the system SHALL display a hero banner at the top; the hero SHALL use a bundled image asset, and IF no asset is available THEN it SHALL fall back to a branded blue gradient banner with the app name so it always renders.
3. WHEN the customer has an active (in-progress) order THEN Home SHALL show that order's current status at a glance with a shortcut into its tracking view; WHEN there is no active order THEN Home SHALL show a neutral empty state.
4. WHEN Home is shown THEN it SHALL provide an entry point into Discovery (for example a search field or a find-laundry action).
5. WHEN Home is shown THEN it SHALL display specialty shortcuts that navigate into Discovery pre-filtered by the selected specialty tag.
6. WHEN Home is shown THEN it SHALL display the customer's loyalty points balance and available vouchers, and the full wallet experience (viewing balance, viewing/redeeming vouchers) SHALL live on the Home area rather than under Profile.
7. WHEN the customer has previous orders THEN Home SHALL offer a reorder shortcut that starts a new order based on a prior order.
8. All Home elements SHALL use the existing theme tokens (blue-dominant palette, spacing, radius, typography) for visual consistency.
10. The system SHALL allow a customer to file a claim only against an order belonging to that customer, and SHALL allow only the order's partner to resolve that claim.

---

## Glossary

- **Customer:** An end user who orders laundry services (User role CUSTOMER).
- **Partner / Laundromat:** A business user that operates a laundromat, sets services and prices, and fulfills orders (User role PARTNER, with an associated Laundromat).
- **Driver:** A user who picks up and delivers laundry for orders (User role DRIVER, with an associated DriverProfile).
- **Per-item pricing:** A service priced per piece; the total is known at checkout (PricingUnit PER_ITEM).
- **Per-kg pricing:** A service priced per kilogram; the final total is only known after the laundry is physically weighed at pickup/intake (PricingUnit PER_KG).
- **Estimate:** The provisional total shown for a per-kg order before weigh-in.
- **Weigh-in:** The step where the partner records the measured weight of a per-kg order, producing the final price.
- **Order lifecycle:** The ordered sequence of statuses an order moves through from placement to completion or cancellation.
- **Offer vs. assignment (driver):** An order is *offered* to a driver who may accept or reject; once accepted it is *assigned* to that driver and no longer offered to others.
- **Available driver:** A driver whose profile status indicates they can currently receive offers.
- **Delivery fee:** Rp 5.000 base for distance <= 5 km; plus Rp 1.000 per whole kilometer over 5 km (extra distance rounded up).
- **Points:** Loyalty units earned on confirmed payment (5 points per Rp 10.000 paid).
- **Voucher:** A redeemable discount; 100 points redeem for a Rp 10.000-off voucher.
- **Declared item:** A specific item a customer optionally registers for warranty coverage at checkout, with a photo and label.
- **Intake confirmation:** The partner's single-step acknowledgment at intake that the declared items were received, establishing the warranty baseline.
- **Warranty claim:** A customer's request for resolution regarding a declared, partner-confirmed item on a completed order; resolved by the partner, funded by Washly.
- **Midtrans Snap:** The Midtrans-hosted payment interface opened by the app; payment status is confirmed via the backend webhook (the source of truth).
- **Home hub:** The customer's landing tab summarizing activity (hero banner, active-order status, discovery entry, specialty shortcuts, loyalty wallet, reorder).
- **Hero banner:** The prominent image/graphic at the top of Home, from a bundled asset with a branded gradient fallback.
- **Account settings:** The per-user screen (all roles) to edit name/phone, change password, and log out; email is read-only.
- **Availability (driver):** A driver's Active/Not Active state controlling whether they receive delivery offers; not related to internet connectivity.
