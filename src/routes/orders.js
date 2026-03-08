import { Router } from 'express';
import { listOrders, getOrder, createOrder, softDeleteOrder, getOrderTotal, searchOrders } from '../services/order-service.js';
import db from '../db.js';
import { validateId, validateOrderPayload, ORDER_STATUSES } from '../utils/validators.js';
import { formatPrice, formatDate } from '../utils/format.js';

const router = Router();

// List orders (paginated)
router.get('/', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const sort = req.query.sort;
  const status = req.query.status;
  const result = await listOrders({ page, limit, sort, status });

  const orders = result.orders.map((o) => ({
    id: o.id,
    product: o.product_name,
    quantity: o.quantity,
    total: formatPrice(getOrderTotal(o)),
    status: o.status,
    date: formatDate(o.created_at),
  }));

  res.json({ orders, total: result.total, page: result.page });
});

// Get single order
router.get('/:id', async (req, res) => {
  const order = await getOrder(req.params.id);
  if (!order || order.status === 'deleted') {
    return res.status(404).json({ error: 'Order not found' });
  }
  res.json({
    ...order,
    total: formatPrice(getOrderTotal(order)),
    date: formatDate(order.created_at),
  });
});

// Create order
router.post('/', async (req, res) => {
  const { user_id, product_name, quantity, total_cents } = req.body;
  if (!user_id || !product_name || !total_cents) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  const order = await createOrder({ user_id, product_name, quantity, total_cents });
  res.status(201).json(order);
});

// Search orders by product name
router.get('/search', async (req, res) => {
  const q = req.query.q;
  if (!q) return res.status(400).json({ error: 'Missing search query' });
  const results = await searchOrders(q);
  res.json(results.map((o) => ({
    id: o.id,
    product: o.product_name,
    total: formatPrice(getOrderTotal(o)),
    status: o.status,
  })));
});

// Order statistics for admin dashboard
router.get('/stats', async (req, res) => {
  const orders = await db('orders').where('status', '!=', 'deleted');
  const stats = {
    total: orders.length,
    revenue: orders.reduce((sum, o) => sum + (o.total_cents * o.quantity), 0),
    byStatus: {},
  };
  orders.forEach((o) => {
    stats.byStatus[o.status] = (stats.byStatus[o.status] || 0) + 1;
  });
  res.json(stats);
});

// Soft delete order
router.delete('/:id', async (req, res) => {
  const order = await getOrder(req.params.id);
  if (!order || order.status === 'deleted') {
    return res.status(404).json({ error: 'Order not found' });
  }
  await softDeleteOrder(req.params.id);
  res.json({ message: 'Order deleted' });
});

export default router;
