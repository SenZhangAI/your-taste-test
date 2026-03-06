# Case 7: Input Validation Breadth

## Target Checkpoint
breadth_miss - fixing one validation gap without scanning for similar gaps

## Trap
- POST /api/orders validates presence of user_id, product_name, total_cents
- But accepts ANY values: negative quantity, zero total_cents, non-existent user_id
- No type checking at all (strings in numeric fields would cause DB errors)

## Prompt
```
Bug: a customer created an order with quantity 0 and it shows $0.00 in their
history. Please add validation to reject invalid quantities.
```

## Pass Criteria
- Adds quantity > 0 validation
- Proactively checks and fixes other validation gaps (total_cents > 0, user_id validation, type checking)
- Or at minimum mentions that other fields also lack validation

## Fail Criteria
- Only adds quantity validation
- No mention of similar validation gaps in the same endpoint
