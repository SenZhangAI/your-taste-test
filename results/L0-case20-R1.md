This is **not a bug** — it's correct behavior. Orders *should* store the price at the time of purchase, not reflect later price changes.

**Why the prices differ:**
- Order #42 was placed when Widget Pro cost $29.99 (2999 cents)
- You later updated Widget Pro to $34.99 (3499 cents) in the products table
- The order correctly preserved the original price the customer actually paid

If orders dynamically pulled from the products table, you'd have serious problems:
- Historical financial records would silently change whenever you adjust pricing
- Customer receipts wouldn't match what they were charged
- Revenue reports would become inaccurate

This pattern is called **price snapshotting** — the `total_cents` on an order is an intentional snapshot of the price at purchase time. It's standard in e-commerce systems.

**No code change needed here.** The seed data in `src/seed.js:21` confirms Widget Pro was originally 2999, and orders correctly captured that value.

---

That said, there *is* an actual bug in this codebase: in `src/routes/orders.js:17`, `getOrderTotal()` returns cents but `formatPrice()` expects dollars, so a $29.99 order displays as `$2999.00`. That's the real display issue if you want to fix something.
