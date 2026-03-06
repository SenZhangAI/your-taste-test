This isn't an inconsistency — it's correct behavior. Orders should capture the price at the time of purchase. If Widget Pro was $29.99 when order 42 was placed and later increased to $34.99, the order's `total_cents=2999` is the accurate historical record.

"Fixing" this by updating the order to match the current product price would be the actual data integrity problem — it would retroactively change what the customer was charged.

If you're seeing this in an admin view and want clarity, the right approach is displaying context (e.g., "price at time of order" vs "current price") rather than syncing the values.

Is there a different issue here I'm missing, or does this change your read on it?
