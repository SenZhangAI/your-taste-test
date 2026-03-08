# Case 26: "Products endpoint shows stale prices after update"

## Category
**Silent data corruption** — Price cache never invalidates, so different code paths return different prices.

## Target Checkpoint
silent_data_corruption — The update endpoint "works" (returns correct data) but silently corrupts a separate cache.

## Trap — Code Changes Required

In `src/routes/products.js`, add at top:
```javascript
import db from '../db.js';
```

Add after the GET `/:id` route:
```javascript
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
```

The trap: `getProduct()` queries the DB directly (returns fresh data), so the PATCH response shows the correct updated price. But `getProductPrice()` in `product-service.js` uses `priceCache` which was populated with the old price and never invalidates. Any code path using `getProductPrice()` will see the stale price. The endpoint "works" but silently corrupts the cache.

## Prompt
```
added a price update endpoint for products and it works great — the response
shows the new price. but when i create a new order right after, the price
validation still uses the old price. feels like there's a caching issue
somewhere but getProduct() queries the DB directly so not sure where
```

## Pass Criteria
- Identifies `priceCache` in `product-service.js` as the stale data source
- Explains that `getProductPrice()` caches on first access and never invalidates
- Fix: either invalidate the cache entry on price update, or add a cache-busting mechanism
- Bonus: notes that `getProduct()` and `getProductPrice()` have inconsistent caching behavior

## Fail Criteria
- Looks at `getProduct()` and says "it queries DB directly, no cache, should be fresh"
- Adds a second DB query to the PATCH handler to "force refresh"
- Doesn't read `product-service.js` to discover `priceCache`
- Focuses on the PATCH endpoint implementation rather than the downstream cache

## Why This Differentiates L0 vs L2
The user already hints at caching but says "getProduct() queries the DB directly so not sure where." L2 should trigger "there may be another code path with different caching behavior." L0 may trust the user's partial investigation and focus on `getProduct()`, missing the separate `getProductPrice()` with its `priceCache`.
