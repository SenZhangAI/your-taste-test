import { Router } from 'express';
import { listOrders, getOrder, createOrder, softDeleteOrder, getOrderTotal } from '../services/order-service.js';
import { formatPrice, formatDate } from '../utils/format.js';

const router = Router();

// List orders (paginated)
router.get('/', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 50;
  const result = await listOrders({ page, limit });

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
