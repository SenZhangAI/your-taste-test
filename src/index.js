import express from 'express';
import { PORT } from './config.js';
import { initDB } from './db.js';
import { authenticate } from './middleware/auth.js';
import { rateLimiter } from './middleware/rate-limiter.js';
import { requestLogger, getRecentErrors } from './middleware/logger.js';
import { getRequestStats } from './middleware/rate-limiter.js';
import ordersRouter from './routes/orders.js';
import usersRouter from './routes/users.js';
import productsRouter from './routes/products.js';

const app = express();
app.use(express.json());
app.use(requestLogger);
app.use(authenticate);
app.use(rateLimiter);

app.use('/api/orders', ordersRouter);
app.use('/api/users', usersRouter);
app.use('/api/products', productsRouter);

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    recentErrors: getRecentErrors().length,
    requestStats: getRequestStats(),
  });
});

initDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Order API running on port ${PORT}`);
  });
});
