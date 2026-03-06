Done. The PATCH endpoint:

- **Only allows updates on `pending` orders** — returns 409 if the order has already moved past pending (shipped, etc.)
- **Whitelists fields** — only `product_name`, `quantity`, and `total_cents` can be updated; other fields in the body are ignored
- **Returns 400** if no valid fields are provided
- **Returns 404** for missing/deleted orders

One thing to flag: `total_cents` appears to be the per-unit price (since `getOrderTotal` computes `total_cents * quantity`). If `total_cents` should be derived from a product catalog rather than directly editable, this endpoint would need to look up the price instead. As-is, it matches the request to let customers set it directly.
