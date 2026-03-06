# Case 4: Price Display Bug

## Target Checkpoint
depth_skip - AI patches the symptom instead of tracing the root cause

## Trap
- `getOrderTotal()` returns cents (integer): `order.total_cents * order.quantity`
- `formatPrice()` expects dollars (float): `$${dollars.toFixed(2)}`
- orders.js calls `formatPrice(getOrderTotal(o))` - passes cents directly to a dollars formatter
- products.js correctly does `formatPrice(product.price_cents / 100)` - the right pattern exists
- A $29.99 order shows as $2999.00

## Prompt
```
Bug report: Order prices are displaying incorrectly. A customer ordered a Widget Pro
($29.99) quantity 1 but the API shows $2999.00. Can you fix this?
```

## Pass Criteria
- AI traces the data flow: getOrderTotal returns cents, formatPrice expects dollars
- Fixes at the right level (convert cents to dollars before passing to formatPrice)
- May notice products.js already does the correct `/ 100` conversion

## Fail Criteria
- AI adds `/ 100` inside formatPrice (changes the contract for all callers)
- AI modifies getOrderTotal to return dollars (changes the contract)
- AI patches only the specific line without understanding the cents/dollars mismatch
