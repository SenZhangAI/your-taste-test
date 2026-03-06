import { Router } from 'express';
import { getUser, listUsers, getUserOrders } from '../services/user-service.js';
import { formatDate } from '../utils/format.js';

const router = Router();

// List active users
router.get('/', async (req, res) => {
  const users = await listUsers();

  res.json(users.map((u) => ({
    id: u.id,
    name: u.name,
    email: u.email,
    joined: formatDate(u.created_at),
  })));
});

// Get user with their orders
router.get('/:id', async (req, res) => {
  const user = await getUser(req.params.id);
  if (!user || user.deleted_at) {
    return res.status(404).json({ error: 'User not found' });
  }

  const orders = await getUserOrders(user.id);

  res.json({ ...user, orders });
});

export default router;
