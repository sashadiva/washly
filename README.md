# Washly 🧺

Washly is an on-demand laundry marketplace built with **Flutter** (Mobile Frontend), **Node.js/Express with TypeScript** (Backend), and **PostgreSQL with Prisma ORM** (Database).

---

## Project Architecture

```text
Washly/
├── Backend/          # Node.js, Express, TypeScript, Prisma ORM, PostgreSQL
└── Frontend/         # Flutter application with Dio, Material 3, Custom Style Guide
```

---

## Prerequisites

- [Node.js](https://nodejs.org/) (v18 or higher)
- [PostgreSQL](https://www.postgresql.org/) (v14 or higher) running locally or remotely
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19 or higher)
- Android Studio / VS Code with Android Emulator or Physical Device

---

## Setup & Running the Backend

### 1. Navigate to Backend Directory
```bash
cd Backend
npm install
```

### 2. Configure Environment Variables
Create a `.env` file inside `Backend/`:
```env
PORT=5000
DATABASE_URL="postgresql://<DB_USER>:<DB_PASSWORD>@localhost:5432/washly_db?schema=public"
```

### 3. Run Migrations & Generate Prisma Client
```bash
npx prisma migrate dev --name init
npx prisma generate
```

### 4. Seed Demo Data
Populates marketplace categories, partner laundromats, and dynamic service menus:
```bash
npx tsx prisma/seed.ts
```

### 5. Start the Server
```bash
npm run dev
```
The server will boot up at `http://localhost:5000`.

---

## Setup & Running the Flutter App

### 1. Navigate to Frontend Directory
```bash
cd Frontend
flutter pub get
```

### 2. Configure API Endpoint
In `Frontend/lib/core/api_client.dart` (or wherever your `dio` base URL is defined), ensure the base URL matches your testing environment:
- **Android Emulator:** `http://10.0.2.2:5000/api`
- **iOS Simulator:** `http://localhost:5000/api`
- **Physical Device:** `http://<YOUR_LOCAL_IP>:5000/api` (e.g., `http://192.168.1.10:5000/api`)

### 3. Run the App
```bash
flutter run
```

---

## Features
- **Discovery Feed:** Filter laundromats by specialty tags (`shoes`, `bags`, `dolls`, `costumes`, `kiloan`) and sort by rating or distance.
- **Dynamic Catalog:** Each laundromat serves its own database-driven service menus, pricing, and units (`PER_KG` vs `PER_ITEM`).
- **Interactive Basket:** Stepper-based item addition and kilogram specifications.
- **Dedicated Checkout:** Pickup and delivery location configuration with driver notes and bill breakdown.
- **Review System:** Customer ratings (1–5 stars) with real-time average store recalculation.