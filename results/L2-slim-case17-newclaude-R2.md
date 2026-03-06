Before implementing — `total_cents` shouldn't be directly editable by customers. That's a price field; letting customers set it means they can change their own prices. The existing code uses `total_cents` as unit price (display total = `total_cents * quantity` in `getOrderTotal`).

I'd recommend: allow updating `product_name` and `quantity`, but recalculate `total_cents` from the product's current price if the product changes, or keep it locked to the original price if only quantity changes. 

That said, if this is an **admin** endpoint and you want all three editable, I'll do that. Which approach do you want?

Either way, I'll restrict edits to orders with `status = 'pending'` (pre-shipment). Sound right?
