import { Router } from 'express';
import db from '../db.js';
import { formatPrice } from '../utils/format.js';

const router = Router();

// List available products
router.get('/', async (req, res) => {
  const products = await db('products')
    .where('status', '!=', 'deleted')
    .orderBy('name');

  res.json(products.map((p) => ({
    id: p.id,
    name: p.name,
    price: formatPrice(p.price_cents / 100),
    stock: p.stock,
  })));
});

// Get product details
router.get('/:id', async (req, res) => {
  const product = await db('products').where({ id: req.params.id }).first();
  if (!product || product.status === 'deleted') {
    return res.status(404).json({ error: 'Product not found' });
  }
  res.json({
    ...product,
    price: formatPrice(product.price_cents / 100),
  });
});

export default router;
