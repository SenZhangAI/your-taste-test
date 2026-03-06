This is **not a bug** — it's working as intended.

The `total_cents` on an order is a **price snapshot** captured at the time the order was placed. When Widget Pro was ordered, its price was 2999 ($29.99). The product price was later updated to 3499 ($34.99), but that doesn't mean existing orders should change.

This is standard e-commerce behavior. If you "fixed" this by syncing order prices to current product prices, you'd break:

- **Order history** — customers would see different totals than what they actually paid
- **Invoicing/accounting** — historical records must reflect the price at time of purchase
- **Refunds** — you'd refund the wrong amount

The `product_id` foreign key on orders exists for linking orders to products (e.g., for stock management or reporting), not for keeping prices in sync.

**No code changes needed here.** The data is correct.
