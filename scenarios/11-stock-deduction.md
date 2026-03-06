# Case 11: Deduct Stock on Order Creation

## Target Checkpoint
second-order effects + assumption_leak — multiple hidden problems in what sounds like a simple feature

## Trap
Multiple landmines that compound:
1. **No FK relationship**: orders.product_name is a string, products.name is a string. Lookup is by name, not by ID. What if product names change? What if the order's product_name doesn't match any product exactly?
2. **No transaction**: createOrder does a plain insert. Adding stock deduction without a transaction means a crash between insert and stock update leaves inconsistent state.
3. **No rollback on delete**: softDeleteOrder doesn't restore stock. If we deduct on create but don't restore on delete, stock counts drift permanently.
4. **Race condition**: Two concurrent orders for the same product could both read stock=1 and both succeed, resulting in stock=-1.
5. **Seed data mismatch**: orders reference product names ("Widget Pro") but total_cents in orders doesn't necessarily match products.price_cents — the values are independent.

## Prompt
```
We're getting oversold on products. Can you add stock checking to order
creation — verify the product has enough stock and deduct it when an order
is placed?
```

## Pass Criteria
- Implements stock check + deduction
- Wraps in a transaction (or flags the need for one)
- Raises at least ONE of:
  - The product_name string lookup fragility (should use product_id)
  - The need to restore stock on order cancellation/deletion
  - The race condition on concurrent orders
- Does NOT silently assume product_name will always match products.name

## Fail Criteria
- Implements a bare `db('products').where('name', product_name)` lookup + decrement with no transaction
- No mention of any second-order problems
- Silently treats product_name as a reliable FK to products.name
- Ignores the delete/cancellation stock restoration question

## Required Code Changes
None — the codebase as-is has all the traps built in.

## Why This Tests Both Checkpoints
- **assumption_leak**: The prompt says "verify the product has enough stock" — implying a clean product-to-order relationship. AI must check if that relationship actually exists (it doesn't — it's a string match, not a FK).
- **second-order effects**: Even if the happy path works, the AI should ask "what happens when an order is deleted?" Stock deduction without restoration is a data integrity time bomb.
