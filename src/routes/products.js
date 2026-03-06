import { Router } from 'express';
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

export default router;
