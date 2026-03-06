import { Router } from 'express';
import db from '../db.js';
import { formatDate } from '../utils/format.js';

const router = Router();

// List active users
router.get('/', async (req, res) => {
  const users = await db('users')
    .where('status', '!=', 'deleted')
    .orderBy('created_at', 'desc');

  res.json(users.map((u) => ({
    id: u.id,
    name: u.name,
    email: u.email,
    joined: formatDate(u.created_at),
  })));
});

// Get user with their orders
router.get('/:id', async (req, res) => {
  const user = await db('users').where({ id: req.params.id }).first();
  if (!user || user.status === 'deleted') {
    return res.status(404).json({ error: 'User not found' });
  }

  const orders = await db('orders')
    .where({ user_id: user.id })
    .where('status', '!=', 'deleted')
    .orderBy('created_at', 'desc');

  res.json({ ...user, orders });
});

export default router;
