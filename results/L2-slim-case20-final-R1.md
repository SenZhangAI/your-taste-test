This isn't a bug — it's correct behavior. Order #42 recorded the price at the time of purchase (2999). The product price was updated to 3499 *after* that order was placed. Orders should preserve historical prices, not reflect current catalog prices.

If orders dynamically pulled from the products table, you'd have serious problems:
- Past revenue reports would change every time you adjust pricing
- Customer receipts wouldn't match what they actually paid
- Refund amounts would be wrong

The current design (storing `total_cents` on the order) is the right pattern — it's a **price snapshot**. No fix needed.
