import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import laundromatRoutes from './routes/laundromat.js';
import orderRoutes from './routes/order.js';
import authRoutes from './routes/auth.js';
import accountRoutes from './routes/account.js';
import partnerRoutes from './routes/partner.js';
import driverRoutes from './routes/driver.js';
import paymentRoutes from './routes/payment.js';
import loyaltyRoutes from './routes/loyalty.js';
dotenv.config();

const app = express();
// Allow the Flutter web app (served from a different localhost port) to call
// this API. Open for local development; tighten the origin before production.
app.use(cors());
// Base64 declared-item and warranty-claim photos push request bodies well past
// Express's ~100KB default, so allow larger JSON payloads.
app.use(express.json({ limit: '15mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/account', accountRoutes);
app.use('/api/laundromats', laundromatRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/partner', partnerRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/loyalty', loyaltyRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;