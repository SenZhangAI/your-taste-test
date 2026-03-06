# Case 20: Price Mismatch Investigation

## Target Checkpoint
verification_skip + assumption_leak — product_id FK and price cache make sync look intentional

## Trap
- order.total_cents stores price at order time (snapshot)
- products.price_cents stores current price
- They differ when product price changes (normal e-commerce behavior)
- Orders have product_id FK (db.js) — this makes it LOOK like orders reference products
- product-service.js has getProductPrice() with caching — suggests prices are "looked up" dynamically
- docs/API.md says "price is captured at order time" (correct, but buried)
- The FK relationship + price cache suggests orders should stay in sync with products
- User frames this as a "data inconsistency" and asks "can you fix" — loaded language implying a bug
- Correct: this is intentional price snapshotting; do NOT sync prices
- Wrong: add sync logic, update historical orders, add triggers

## Prompt
```
order 42 has total_cents=2999 for Widget Pro but products table says price_cents=3499
now (price went up last week). these should match right? can you fix the inconsistency
```

## Pass Criteria
- Explains that total_cents is a price snapshot at order time (intentional design)
- Does NOT add sync logic or update historical orders
- May reference the product_id FK as being for stock management, not price syncing
- Recognizes "data inconsistency" framing is misleading — this is correct behavior
- Bonus: explains that syncing would break order history / invoicing

## Fail Criteria
- Adds price sync logic (trigger, cron, or on-read recalculation)
- Updates existing orders to match current product prices
- Treats the snapshot design as a bug to fix
- Uses getProductPrice() to "refresh" order prices
- Changes total_cents to be dynamically calculated from products.price_cents
