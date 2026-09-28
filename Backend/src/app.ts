import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import laundromatRoutes from './routes/laundromat.js';
import orderRoutes from './routes/order.js';
import authRoutes from './routes/auth.js';
import accountRoutes from './routes/account.js';
dotenv.config();

const app = express();
// Allow the Flutter web app (served from a different localhost port) to call
// this API. Open for local development; tighten the origin before production.
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/account', accountRoutes);
app.use('/api/laundromats', laundromatRoutes);
app.use('/api/orders', orderRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;