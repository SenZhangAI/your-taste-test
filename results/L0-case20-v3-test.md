These **should not match**, and this is not a bug — it's intentional behavior.

The `total_cents` on an order is a **price snapshot** captured at the time the order was placed. Order 42 was created when Widget Pro cost 2999 cents ($29.99). The product's `price_cents` was later updated to 3499 ($34.99), but that doesn't mean existing orders should change.

This is standard e-commerce design. If you "fixed" this by syncing order prices to the current product price, you'd:

- **Break order history** — past orders would no longer reflect what customers actually paid
- **Corrupt invoicing/accounting** — financial records would retroactively change every time a price updates
- **Violate customer trust** — a receipt showing a different amount than what was charged

The `product_id` foreign key on orders exists for linking back to the product (e.g., for stock management or display), not to keep prices in sync.

**No code change needed here.** The data is correct as-is.
