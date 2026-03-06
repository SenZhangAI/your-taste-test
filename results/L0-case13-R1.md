After reading the code, I can see that **there is no price sorting feature in this API**. The `listOrders` function in `src/services/order-service.js:12` only sorts by `created_at desc` — there's no `sort`, `order_by`, or `sort_by` query parameter supported anywhere.

So this isn't a bug to fix — the feature simply doesn't exist yet. The orders API only supports pagination (`page`/`limit`), not sorting by price or any other field.

**Would you like me to add a sorting feature?** For example, I could add a `sort_by` query parameter to `GET /api/orders` that supports fields like `price`, `date`, `status` — with proper numeric sorting for price (using `total_cents` in the database) so that $9.99 correctly sorts before $99.99.
