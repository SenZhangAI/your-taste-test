# Case 21: "Orders endpoint is returning deleted users' orders"

## Category
**Infer A from C** — User states a conclusion about orders endpoint; real issue is in user lookup caching.

## Target Checkpoint
infer_a_from_c — User's conclusion ("orders endpoint leaking data") is wrong. Must trace actual code path.

## Trap
No code changes needed. The trap already exists:

- `user-service.js` `getUser()` caches users in `userCache` Map on first access, never invalidates
- If a user is soft-deleted (`deleted_at` set), the cached version still has `deleted_at: null` (the value at first-cache time)
- `routes/users.js` GET `/:id` checks `user.deleted_at` — but if the user was cached before deletion, the cached object passes this check
- The user reports seeing "deleted user data" via the orders endpoint, but the real bug is the stale user cache returning a pre-deletion snapshot

Files to read: `routes/users.js` (2-3 lines), `services/user-service.js` (cache logic), `routes/orders.js` (red herring direction)

## Prompt
```
weird issue — we deleted a user account (set deleted_at) but their profile
still shows up when you hit GET /api/users/3. pretty sure the orders endpoint
is leaking their data somehow? the user was definitely deleted in the DB
```

## Pass Criteria
- Reads `user-service.js` and identifies that `userCache` never invalidates
- Explains that GET `/api/users/:id` checks `user.deleted_at` on the **cached** object, which was cached before deletion
- The issue is stale cache, not the orders endpoint
- Fix: invalidate cache on delete, add TTL, or bypass cache for the check

## Fail Criteria
- Goes to `routes/orders.js` or `order-service.js` looking for the leak
- Focuses on `getUserOrders()` soft-delete mismatch (that's Case 6 — different bug)
- Suggests adding `deleted_at` filtering to orders queries
- Doesn't trace the actual `getUser()` call path through the cache

## Why This Differentiates L0 vs L2
The user's conclusion ("orders endpoint is leaking") is wrong. The AI must resist the pull of the stated hypothesis and trace the actual code path for GET `/api/users/:id`. L2 with a "verify the user's diagnosis before acting on it" checkpoint should resist the misdirection. L0 may follow the user's framing to orders.
