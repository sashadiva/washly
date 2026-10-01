# Washly 🧺

Washly is an on-demand laundry marketplace with a full order lifecycle, three user roles (**customer**, **laundromat partner**, **driver**), live driver assignment, Midtrans payments, loyalty vouchers, declared-item warranty, and English/Indonesian localization.

- **Frontend:** Flutter (Material 3, Dio, Provider), runs on Android, web (Chrome), and desktop.
- **Backend:** Node.js + Express + TypeScript, Prisma ORM.
- **Database:** PostgreSQL.
- **Payments:** Midtrans Snap (sandbox).

---

## Project layout

```text
washly/
├── Backend/            # Express + TypeScript API, Prisma schema/migrations/seed
├── Frontend/           # Flutter app (customer / partner / driver)
├── docker-compose.yml  # Postgres + backend for local dev
└── README.md
```

---

## The fastest way to run it (Docker)

This is the recommended path — it brings up Postgres **and** the backend, applies migrations, and seeds demo data automatically. You only run the Flutter app yourself.

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.8+)
- For Android: Android Studio with an emulator, **and a JDK 17–21** (see the Java note below)

### 1. Backend env file
Copy the example and fill in the values:
```bash
cp Backend/.env.example Backend/.env
```
Minimum to boot (payments optional — see the Midtrans section):
```env
PORT=5000
DATABASE_URL="postgresql://washly:washly@localhost:5433/washly?schema=public"
JWT_SECRET="change_me_for_local"
JWT_EXPIRES_IN="7d"
MIDTRANS_SERVER_KEY=""
MIDTRANS_CLIENT_KEY=""
MIDTRANS_IS_PRODUCTION=false
APP_WEBHOOK_BASE_URL=""
```
> `.env` is gitignored (never commit it). Inside Docker, `DATABASE_URL` is overridden to the compose `db` host automatically; the `localhost:5433` value is for running Prisma CLI from your host against the same container.

### 2. Start the stack (from the repo root)
```bash
docker compose up --build
```
What this does:
- Starts PostgreSQL (host port **5433** → container 5432, so it won't clash with a local Postgres).
- Waits for the DB, runs `prisma migrate deploy`, seeds demo data, then starts the backend with hot reload.
- Backend is live at **http://localhost:5000**.

When to use `--build` vs plain `docker compose up`:
- Use `--build` the first time, or after changing `Backend/package.json` or the `Dockerfile`.
- Plain `docker compose up` is enough when you only changed backend source (it's bind-mounted and hot-reloads).

Stop it with `Ctrl+C`, or `docker compose down`. Add `-v` (`docker compose down -v`) **only** if you want to wipe the database.

### 3. Run the Flutter app (in your own terminal)
```bash
cd Frontend
flutter pub get
```
Then pick a target:

**Chrome (easiest, no Android toolchain):**
```bash
flutter run -d chrome
```
> The web Snap payment popup needs the Midtrans client key in `Frontend/web/index.html` (`data-client-key`). See the Midtrans section.

**Android emulator:**
```bash
flutter devices           # find the emulator id, e.g. emulator-5554
flutter run -d emulator-5554
```

The app auto-detects the backend URL by platform (no config needed):
- Android emulator → `http://10.0.2.2:5000/api`
- Web / iOS / desktop → `http://localhost:5000/api`

---

## Demo accounts

All seeded accounts use the password **`password123`**:

| Role     | Email                           |
|----------|---------------------------------|
| Customer | `customer@washly.com`           |
| Partner  | `partner.cleanwave@washly.com`  |
| Partner  | `partner.sneakerspa@washly.com` |
| Driver   | `driver.andi@washly.com`        |
| Driver   | `driver.budi@washly.com`        |

The seed also creates laundromats, services, in-flight orders at various lifecycle stages, delivery offers, and declared items so every screen has something to show.

---

## Java note for Android builds (important)

The project's Gradle toolchain needs **JDK 17–21**. If your system Java is newer (e.g. 25), `flutter run` on Android fails with a Gradle/Java incompatibility. Fix it by pointing Flutter at a JDK 21:

```bash
# Debian/Ubuntu example
sudo apt-get install -y openjdk-21-jdk
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
```
This leaves your system Java untouched and only affects Flutter's Android builds. (Not needed for `flutter run -d chrome`.)

---

## Midtrans payments (sandbox)

Payments use Midtrans Snap in sandbox mode. To enable the pay flow:

1. Get your **Sandbox** keys from the Midtrans dashboard → Settings → Access Keys.
2. Put the **server** and **client** keys in `Backend/.env` (`MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`), keep `MIDTRANS_IS_PRODUCTION=false`.
3. Put the **same client key** in `Frontend/web/index.html` → `data-client-key` (only needed for the web build; the client key is safe to expose).
4. Restart the backend (`docker compose up`) and, for web, do a full `flutter run` restart + hard browser refresh.

Sandbox test card for a successful payment:
- Card `4811 1111 1111 1114`, CVV `123`, any future expiry, OTP `112233`.

> Payments are optional for exploring the app. Without keys you can still browse, place orders, and walk most of the flow; only the Snap payment step needs them.

---

## Language

The app ships in **English** and **Indonesian**. Switch anytime in **Account → Change Language**; the whole UI updates instantly.

---

## Running the backend without Docker (optional)

If you'd rather run Node directly against your own Postgres:
```bash
cd Backend
npm install
# point DATABASE_URL in .env at your Postgres
npx prisma migrate dev
npm run seed
npm run dev            # http://localhost:5000
```

---

## Feature overview

- **Three roles** with separate home shells: customer, laundromat partner, driver.
- **Full order lifecycle:** place → partner accepts → driver pickup (customer → laundromat) → partner receives & weighs → customer approves price → payment → washing → driver delivery (laundromat → customer) → completed.
- **Two delivery legs** with live driver assignment to the nearest available driver.
- **Dynamic per-laundromat catalog** with `PER_KG` and `PER_ITEM` pricing. Per-kg price is set by the laundromat at weigh-in and approved by the customer before payment.
- **Declared items + warranty:** photograph valuables at checkout (flat protection fee); the partner confirms intake on arrival; customers can file claims on completed orders.
- **Loyalty & vouchers:** earn points, redeem for discount vouchers, apply them at checkout.
- **Vehicle visibility:** customer and partner see the assigned driver's vehicle/plate at the right handoff moments.
- **Reviews:** 1–5 star ratings with live store-average recalculation.
- **Midtrans Snap** sandbox payments with webhook settlement.
- **English / Indonesian** localization.
