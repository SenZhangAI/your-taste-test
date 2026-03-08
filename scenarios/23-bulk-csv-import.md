# Case 23: "Add bulk order import from CSV"

## Category
**Enumerate from first principles** — The obvious approach (parse CSV, loop insert) has fundamental flaws given the existing codebase.

## Target Checkpoint
enumerate_from_first_principles — Must consider transaction boundaries, data resolution, and partial failure before writing code.

## Trap
No code changes needed. The trap is in the existing architecture:

- `createOrder()` does individual `db('orders').insert()` calls — no batch support
- No transactions anywhere in the codebase
- `product_name` is a string (not validated against products table)
- No `product_id` is required by route handler (only `user_id`, `product_name`, `total_cents`)
- `total_cents` is provided by the caller, not derived from products — CSV could have any price
- CSV provides `user_email` but orders table needs `user_id` — requires lookup
- If import fails at row 500 of 1000, the first 499 orders are committed with no rollback

## Prompt
```
customers want to upload a CSV of past orders for migration. format is:
user_email, product_name, quantity, total_cents, date
add a POST /api/orders/import endpoint that takes a CSV file
```

## Pass Criteria
- Considers transaction wrapping for atomicity (all-or-nothing import)
- Notices that `user_email` needs to be resolved to `user_id` (requires user lookup)
- Raises at least one of:
  - What if user_email doesn't exist in users table?
  - What if product_name doesn't match any product?
  - total_cents from CSV may not match current product prices (is that OK for historical data?)
  - Batch insert for performance vs. row-by-row validation
- Uses batch insert rather than calling `createOrder()` in a loop

## Fail Criteria
- Loops through CSV rows calling `createOrder()` one by one with no transaction
- Assumes user_email can be used directly (doesn't resolve to user_id)
- No error handling for partial failures
- Doesn't question whether CSV product_name/total_cents should be validated against products table

## Why This Differentiates L0 vs L2
The AI should consider "what could go wrong with 1000 inserts?" before writing code. L2's "consider alternatives before diving in" should trigger evaluation of: transaction boundaries, batch vs. loop, email-to-ID resolution, and partial failure handling. L0 may just parse CSV and loop `createOrder()`.
