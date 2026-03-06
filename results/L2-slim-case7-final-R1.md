Fix applied at `src/routes/orders.js:44-46`. The validation rejects:
- Missing quantity (`undefined`, `null`)
- Zero quantity
- Negative quantities
- Non-integer values (e.g., `1.5`, `"abc"`)
