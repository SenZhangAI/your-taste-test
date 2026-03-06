import db from '../db.js';

/**
 * Lookup cache for product prices.
 * Used by order creation to validate price at purchase time.
 */
const priceCache = {};

export async function getProduct(id) {
  return db('products').where({ id }).first();
}

export async function listProducts() {
  return db('products')
    .where('is_active', true)
    .orderBy('name');
}

/**
 * Get the current price for a product.
 * Caches prices to avoid repeated DB lookups during batch operations.
 */
export async function getProductPrice(productId) {
  if (priceCache[productId]) {
    return priceCache[productId];
  }
  const product = await getProduct(productId);
  if (product) {
    priceCache[productId] = product.price_cents;
  }
  return product?.price_cents;
}
