Added `deleted_at: db.fn.now()` to `softDeleteOrder` at `order-service.js:74`.

This was actively causing a bug: `getUserOrders` in user-service.js:36 filters with `.whereNull('deleted_at')`, so deleted orders were leaking into user profiles since `deleted_at` was never set.

Re: products — products doesn't have a `deleted_at` column at all (it uses `is_active` boolean). Aligning would require a schema change, which is a separate migration with its own considerations. I'd leave that for a dedicated effort rather than bundling it with this bugfix.
