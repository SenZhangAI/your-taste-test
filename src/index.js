import express from 'express';
import { PORT, RATE_LIMIT } from './config.js';
import { initDB } from './db.js';
import ordersRouter from './routes/orders.js';
import usersRouter from './routes/users.js';
import productsRouter from './routes/products.js';

const app = express();
app.use(express.json());

// Simple rate limiting (in-memory)
const hits = new Map();
app.use((req, res, next) => {
  const ip = req.ip;
  const now = Date.now();
  const windowStart = now - 60_000;

  const ipHits = (hits.get(ip) || []).filter((t) => t > windowStart);
  if (ipHits.length >= RATE_LIMIT) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }
  ipHits.push(now);
  hits.set(ip, ipHits);
  next();
});

app.use('/api/orders', ordersRouter);
app.use('/api/users', usersRouter);
app.use('/api/products', productsRouter);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Order API running on port ${PORT}`);
  });
});
