import { Router } from 'express';
import db from '../db.js';
import { getProduct, listProducts } from '../services/product-service.js';
import { formatPrice } from '../utils/format.js';

const router = Router();

// List available products
router.get('/', async (req, res) => {
  const products = await listProducts();

  res.json(products.map((p) => ({
    id: p.id,
    name: p.name,
    price: formatPrice(p.price_cents / 100),
    stock: p.stock,
  })));
});

// Get product details
router.get('/:id', async (req, res) => {
  const product = await getProduct(req.params.id);
  if (!product || !product.is_active) {
    return res.status(404).json({ error: 'Product not found' });
  }
  res.json({
    ...product,
    price: formatPrice(product.price_cents / 100),
  });
});

// Update product price
router.patch('/:id', async (req, res) => {
  const { price_cents } = req.body;
  if (!price_cents || price_cents <= 0) {
    return res.status(400).json({ error: 'Invalid price' });
  }
  await db('products').where({ id: req.params.id }).update({ price_cents });
  const product = await getProduct(req.params.id);
  res.json({
    ...product,
    price: formatPrice(product.price_cents / 100),
  });
});

export default router;
