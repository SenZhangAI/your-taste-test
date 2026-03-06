Here's what I changed:

**`src/services/order-service.js`** — `createOrder` now:
1. Runs inside a **transaction** to prevent race conditions
2. Looks up the product by name (must be active)
3. Checks `product.stock >= quantity`, throws if insufficient
4. **Deducts stock** before inserting the order

**`src/routes/orders.js`** — The POST handler now catches stock errors:
- **404** if the product doesn't exist
- **409 Conflict** if there's insufficient stock
- Other errors re-throw to the global error handler
